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
	c := kong.Parse(&cli, kong.BindTo(ctx, (*context.Context)(nil)))
	if err := c.Run(); err != nil {
		slog.ErrorContext(ctx, "command failed", "error", err)
		os.Exit(1)
	}
}
