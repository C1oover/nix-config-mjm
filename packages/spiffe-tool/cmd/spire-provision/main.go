package main

import (
	"context"

	"github.com/alecthomas/kong"
)

type CLI struct {
	Run RunCmd `cmd:"" default:"withargs"`
}

func main() {
	ctx := context.Background()

	var cli CLI
	c := kong.Parse(&cli, kong.BindTo(ctx, (*context.Context)(nil)))
	c.FatalIfErrorf(c.Run())
}
