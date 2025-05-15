package main

import (
	"context"
	"log/slog"
	"os"

	"github.com/alecthomas/kong"
)

type CLI struct {
	Serve ServeCmd `cmd:"" default:"withargs"`
}

func main() {
	ctx := context.Background()

	var cli CLI
	c := kong.Parse(&cli, kong.BindTo(ctx, (*context.Context)(nil)), kong.Vars{
		"creds_dir": os.Getenv("CREDENTIALS_DIRECTORY"),
	})
	if err := c.Run(); err != nil {
		slog.Error("spiffe-garage failed", "error", err)
		os.Exit(1)
	}
}
