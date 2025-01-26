package nix

import "context"

type Nix interface {
	Realise(ctx context.Context, drvPath string, useNom bool) (string, error)
	EvalJobs(ctx context.Context, opts EvalJobsOptions) ([]EvalJobResult, error)
	EvalJSON(ctx context.Context, dst interface{}, opts EvalOptions) error
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

type Real struct{}
