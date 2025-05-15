package main

import (
	"context"
	"log/slog"
	"os"

	"github.com/alecthomas/kong"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/sdk/resource"
	"go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.20.0"
)

var tracer = otel.Tracer("git.midna.dev/mjm/nix-config/packages/spiffe-tool/cmd/spiffe-garage")

type CLI struct {
	Serve ServeCmd `cmd:"" default:"withargs"`
}

func main() {
	ctx := context.Background()

	exp, err := otlptracehttp.New(ctx)
	if err != nil {
		panic(err)
	}

	res, err := resource.New(ctx, resource.WithFromEnv(),
		resource.WithTelemetrySDK(),
		resource.WithOS(),
		resource.WithHost(),
		resource.WithAttributes(semconv.ServiceName("spiffe-garage")))
	if err != nil {
		panic(err)
	}

	tracerProvider := trace.NewTracerProvider(
		trace.WithBatcher(exp),
		trace.WithResource(res))
	defer func() {
		if err := tracerProvider.Shutdown(ctx); err != nil {
			panic(err)
		}
	}()
	otel.SetTracerProvider(tracerProvider)

	var cli CLI
	c := kong.Parse(&cli, kong.BindTo(ctx, (*context.Context)(nil)), kong.Vars{
		"creds_dir": os.Getenv("CREDENTIALS_DIRECTORY"),
	})
	if err := c.Run(); err != nil {
		slog.Error("spiffe-garage failed", "error", err)
		os.Exit(1)
	}
}
