package main

import (
	"context"
	"fmt"
	"log/slog"
	"strings"
)

type ServeCmd struct {
	ListenAddress string `default:"127.0.0.1:8080"`
	BaseURL       string `default:"http://localhost:8080"`
	TrustDomain   string `env:"SPIFFE_USERS_TRUST_DOMAIN"`

	OIDC struct {
		ProviderURL  string `env:"SPIFFE_USERS_OIDC_PROVIDER_URL"`
		ClientID     string `env:"SPIFFE_USERS_OIDC_CLIENT_ID"`
		ClientSecret []byte `name:"client-secret-file" type:"filecontent" env:"SPIFFE_USERS_OIDC_CLIENT_SECRET_FILE"`
	} `embed:"" prefix:"oidc."`
}

func (c *ServeCmd) Run(ctx context.Context) error {
	slog.InfoContext(ctx, "running serve", "trust_domain", c.TrustDomain)

	s, err := NewServer(ctx, &ServerConfig{
		TrustDomain:      c.TrustDomain,
		BaseURL:          c.BaseURL,
		OIDCProviderURL:  c.OIDC.ProviderURL,
		OIDCClientID:     c.OIDC.ClientID,
		OIDCClientSecret: strings.TrimSpace(string(c.OIDC.ClientSecret)),
	})
	if err != nil {
		return fmt.Errorf("creating server: %w", err)
	}

	s.Serve(c.ListenAddress)
	return nil
}
