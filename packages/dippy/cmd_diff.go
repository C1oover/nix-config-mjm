package main

import (
	"context"
	"fmt"
	"io"
	"log/slog"
	"os"
	"path"
	"strconv"
	"strings"

	"git.midna.dev/mjm/nix-config/packages/dippy/infra"
)

type DiffCmd struct {
	DeployFlags
	Hosts []string `arg:"" name:"host" help:"Hosts to build and diff." optional:""`
}

func (c *DiffCmd) Run(ctx context.Context, cli *CLI) error {
	cfg, err := GenerateConfig(ctx)
	if err != nil {
		return fmt.Errorf("generating config: %w", err)
	}
	defer cfg.Cleanup()

	s := sectionStart("Evaluating hosts and tests", true)
	plan, err := cli.EvalNodes(ctx, &cfg, c.Hosts)
	if err != nil {
		return fmt.Errorf("evaluating nodes: %w", err)
	}
	sectionEnd(s)

	slog.DebugContext(ctx, "creating temp dir for diffs")
	diffsDir, err := os.MkdirTemp("", "dippy-diffs")
	if err != nil {
		return fmt.Errorf("creating temp dir: %w", err)
	}
	defer os.RemoveAll(diffsDir)
	slog.DebugContext(ctx, "created temp dir for diffs", "path", diffsDir)

	s = sectionStart("Building hosts", false)
	if err := plan.Build(ctx, c.Nom); err != nil {
		return fmt.Errorf("building all hosts: %w", err)
	}
	sectionEnd(s)

	if c.Tests {
		s = sectionStart("Running NixOS VM tests", false)
		if err := plan.Test(ctx, c.Nom); err != nil {
			return fmt.Errorf("running all tests: %w", err)
		}
		sectionEnd(s)
	}

	if err := atticLogin(ctx, &cfg); err != nil {
		return fmt.Errorf("logging in to attic: %w", err)
	}

	s = sectionStart("Pushing and diffing hosts", true)
	if err := plan.EachHost(ctx, cli.Concurrency, func(ctx context.Context, h *Host) error {
		if c.Attic {
			if err := h.PushToAttic(ctx); err != nil {
				return fmt.Errorf("pushing node %s to attic: %w", h.Name, err)
			}
		}

		if h.IsRemote() {
			if err := h.Push(ctx); err != nil {
				return fmt.Errorf("pushing node %s: %w", h.Name, err)
			}
			diff, err := h.Diff(ctx)
			if err != nil {
				return fmt.Errorf("diffing node %s: %w", h.Name, err)
			}

			f, err := os.Create(path.Join(diffsDir, fmt.Sprintf("%s.json", h.Name)))
			if err != nil {
				return fmt.Errorf("opening file to write diff: %w", err)
			}
			defer f.Close()

			if _, err := f.Write(diff); err != nil {
				return fmt.Errorf("writing diff to %s: %w", f.Name(), err)
			}
		}
		return nil
	}); err != nil {
		return fmt.Errorf("building nodes: %w", err)
	}
	sectionEnd(s)

	if len(c.Hosts) == 0 {
		vault, err := cfg.Vault(ctx)
		if err != nil {
			return fmt.Errorf("getting vault client: %w", err)
		}
		s = sectionStart("Previewing infra changes", false)
		if err := infra.Preview(ctx, vault, plan.Infra); err != nil {
			return fmt.Errorf("previewing infra changes: %w", err)
		}
		sectionEnd(s)
	}

	slog.DebugContext(ctx, "aggregating diffs", "path", diffsDir)
	aggregated, err := aggregateDiffs(ctx, diffsDir)
	if err != nil {
		return fmt.Errorf("aggregating diffs: %w", err)
	}

	var body strings.Builder
	if err := aggregated.Write(&body); err != nil {
		return fmt.Errorf("writing formatted summary: %w", err)
	}

	if body.Len() == 0 {
		body.WriteString("No package changes for server hosts.\n")
	}

	// TODO use flags to control this, pulling from env vars
	gitlabBaseURL := os.Getenv("CI_API_V4_URL")
	if gitlabBaseURL == "" {
		io.WriteString(os.Stdout, body.String())
	} else {
		gitlabToken, err := cfg.GetSecret(ctx, "gitlab_token")

		projectID, err := strconv.Atoi(os.Getenv("CI_PROJECT_ID"))
		if err != nil {
			return fmt.Errorf("converting project ID %q to int: %w", os.Getenv("CI_PROJECT_ID"), err)
		}

		mergeRequestID, err := strconv.Atoi(os.Getenv("CI_MERGE_REQUEST_IID"))
		if err != nil {
			return fmt.Errorf("converting merge request ID %q to int: %w", os.Getenv("CI_MERGE_REQUEST_IID"), err)
		}

		slog.DebugContext(ctx, "creating merge request note", "base_url", gitlabBaseURL, "project", projectID, "merge_request", mergeRequestID)

		if err := createMergeRequestNote(ctx, &createMergeRequestNoteArgs{
			BaseURL:        gitlabBaseURL,
			Token:          gitlabToken,
			Project:        projectID,
			MergeRequestID: mergeRequestID,
			Body:           body.String(),
		}); err != nil {
			return fmt.Errorf("creating merge request note: %w", err)
		}

		slog.InfoContext(ctx, "created merge request note")
	}

	return nil
}
