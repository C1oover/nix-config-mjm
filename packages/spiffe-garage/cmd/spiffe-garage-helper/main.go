package main

import (
	"context"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"

	"github.com/spiffe/go-spiffe/v2/spiffeid"
	"github.com/spiffe/go-spiffe/v2/spiffetls/tlsconfig"
	"github.com/spiffe/go-spiffe/v2/workloadapi"
)

func main() {
	if err := run(); err != nil {
		slog.Error("credential helper failed", "error", err)
		os.Exit(1)
	}
}

func run() error {
	ctx := context.Background()
	source, err := workloadapi.NewX509Source(ctx)
	if err != nil {
		return fmt.Errorf("creating x509 source: %w", err)
	}
	defer source.Close()

	service := spiffeid.RequireFromString("spiffe://home.mattmoriarity.com/svc/spiffe-garage")
	tlsConfig := tlsconfig.MTLSClientConfig(source, source, tlsconfig.AuthorizeID(service))
	c := &http.Client{
		Transport: &http.Transport{
			TLSClientConfig: tlsConfig,
		},
	}

	r, err := http.NewRequestWithContext(ctx, "POST", "https://spiffe-garage.service.consul:3899/creds", nil)
	if err != nil {
		return fmt.Errorf("creating http request: %w", err)
	}

	resp, err := c.Do(r)
	if err != nil {
		return fmt.Errorf("sending http request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		b, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("unexpected status %d: %s", resp.StatusCode, b)
	}

	io.Copy(os.Stdout, resp.Body)
	return nil
}
