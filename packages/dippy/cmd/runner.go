package cmd

import "context"

type Runner interface {
	Execute(ctx context.Context, name string, args ...string) error
	ExecuteOutput(ctx context.Context, name string, args ...string) ([]byte, error)
}
