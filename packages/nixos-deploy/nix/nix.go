package nix

import (
	"context"
	"log/slog"
)

// Nix is an interface for performing operations using nix.
type Nix interface {
	// Realise builds a derivation from a .drv file.
	Realise(ctx context.Context, drvPath string, useNom bool) error
	// EvalJobs evaluates an attribute set of derivations using nix-eval-jobs for
	// parallelization.
	EvalJobs(ctx context.Context, opts EvalJobsOptions) ([]EvalJobResult, error)
	// EvalJSON evaluates an arbitrary Nix expression and decodes the results as
	// JSON.
	EvalJSON(ctx context.Context, dst interface{}, opts EvalOptions) error
	// Copy copies one or more installables to another machine via SSH.
	Copy(ctx context.Context, opts CopyOptions) error
}

type EvalOptions struct {
	Path string
	Expr string
}

type EvalJobsOptions struct {
	Path    string
	Expr    string
	Args    map[string]string
	Workers int
}

type EvalJobResult struct {
	Attr    string            `json:"attr"`
	DrvPath string            `json:"drvPath"`
	Outputs map[string]string `json:"outputs"`
	Error   string            `json:"error"`
}

func (r EvalJobResult) OutPath() string {
	return r.Outputs["out"]
}

// Real is a concrete implementation of [Nix] that calls out to the nix
// command-line tools.
type Real struct {
	SSHOpts []string
}

// New creates a new [Nix] interface that uses the SSH private key at the given path.
func New(keyPath string) Nix {
	args := []string{
		"-o",
		"BatchMode=yes",
		"-T",
	}

	if keyPath != "" {
		args = append(args, "-o", "IdentityFile="+keyPath)
	}

	slog.Debug("ssh options", "opts", args)

	return &Real{SSHOpts: args}
}
