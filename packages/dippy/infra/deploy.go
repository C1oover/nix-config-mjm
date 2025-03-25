package infra

import (
	"context"
	"fmt"
	"log/slog"
	"os"

	"github.com/hashicorp/vault/api"
	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault"
	"github.com/pulumi/pulumi/sdk/v3/go/auto"
	"github.com/pulumi/pulumi/sdk/v3/go/auto/optpreview"
	"github.com/pulumi/pulumi/sdk/v3/go/auto/optup"
	"github.com/pulumi/pulumi/sdk/v3/go/common/workspace"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

type Input struct {
	Vhosts        map[string]bool           `json:"vhosts"`
	VaultServices map[string]map[string]any `json:"vaultServices"`
	VaultPolicies map[string]string         `json:"vaultPolicies"`
	VaultRoles    map[string]RoleInput      `json:"vaultRoles"`
}

type RoleInput struct {
	Policies []string `json:"policies"`
	Services []string `json:"services"`
}

func deploy(input *Input) func(*pulumi.Context) error {
	return func(ctx *pulumi.Context) error {
		if err := setUpMattmoriarityCom(ctx); err != nil {
			return err
		}

		if err := setUpMidnaDev(ctx, input.Vhosts); err != nil {
			return err
		}

		adminGroup, err := setUpVaultAdmin(ctx)
		if err != nil {
			return err
		}

		if err := setUpAuthOIDC(ctx, adminGroup); err != nil {
			return err
		}

		if err := setUpVaultAppRoles(ctx, input.VaultServices, input.VaultPolicies, input.VaultRoles); err != nil {
			return err
		}

		if err := setUpVaultSSH(ctx); err != nil {
			return err
		}

		if err := setUpVaultGitLab(ctx); err != nil {
			return err
		}

		if _, err := vault.NewMount(ctx, "kv", &vault.MountArgs{
			Type: pulumi.String("kv"),
			Path: pulumi.String("kv"),
			Options: pulumi.StringMap{
				"version": pulumi.String("2"),
			},
		}, pulumi.Protect(true)); err != nil {
			return err
		}

		return nil
	}
}

func Apply(ctx context.Context, c *api.Client, input *Input) error {
	slog.InfoContext(ctx, "applying infra changes")

	s, err := setUpStack(ctx, c, input)
	if err != nil {
		return fmt.Errorf("setting up pulumi stack: %w", err)
	}

	out := optup.ProgressStreams(os.Stderr)
	_, err = s.Up(ctx, out, optup.Diff(), optup.Color("always"))
	if err != nil {
		return fmt.Errorf("updating pulumi stack: %w", err)
	}

	slog.InfoContext(ctx, "applied infra changes")

	return nil
}

func Preview(ctx context.Context, c *api.Client, input *Input) error {
	slog.InfoContext(ctx, "previewing infra changes")

	s, err := setUpStack(ctx, c, input)
	if err != nil {
		return fmt.Errorf("setting up pulumi stack: %w", err)
	}

	out := optpreview.ProgressStreams(os.Stderr)
	_, err = s.Preview(ctx, out, optpreview.Diff(), optpreview.Color("always"))
	if err != nil {
		return fmt.Errorf("previewing pulumi stack: %w", err)
	}

	return nil
}

func setUpStack(ctx context.Context, c *api.Client, input *Input) (auto.Stack, error) {
	slog.DebugContext(ctx, "setting up pulumi stack")
	s, err := auto.UpsertStackInlineSource(ctx, "prod", "homelab", deploy(input), auto.Project(workspace.Project{
		Name:    "homelab",
		Runtime: workspace.NewProjectRuntimeInfo("go", nil),
		Backend: &workspace.ProjectBackend{
			URL: "s3://pulumi-state?endpoint=garage.midna.dev&region=home&s3ForcePathStyle=true",
		},
	}), auto.EnvVars(map[string]string{
		"VAULT_TOKEN": c.Token(),
	}))
	if err != nil {
		return auto.Stack{}, fmt.Errorf("upserting pulumi stack: %w", err)
	}

	slog.DebugContext(ctx, "refreshing pulumi stack")
	if _, err := s.Refresh(ctx); err != nil {
		return auto.Stack{}, fmt.Errorf("refreshing pulumi stack: %w", err)
	}

	return s, nil
}
