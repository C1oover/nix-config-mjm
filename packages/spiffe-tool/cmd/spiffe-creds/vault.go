package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"path"
	"strings"

	"github.com/hashicorp/vault/api"
	"github.com/spiffe/go-spiffe/v2/spiffeid"
	"github.com/spiffe/go-spiffe/v2/spiffetls/tlsconfig"
	"github.com/spiffe/go-spiffe/v2/svid/jwtsvid"
	"github.com/spiffe/go-spiffe/v2/workloadapi"
)

func newVaultClient(ctx context.Context) (*api.Client, error) {
	spiffeSocket := os.Getenv("SPIFFE_ENDPOINT_SOCKET")
	if spiffeSocket == "" {
		// if no spiffe socket, assume this is called from somewhere where the
		// vault cli is being used, and try to read the token it stores
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return nil, fmt.Errorf("getting user home dir: %w", err)
		}

		tokenBytes, err := os.ReadFile(path.Join(homeDir, ".vault-token"))
		if err != nil {
			return nil, fmt.Errorf("reading vault token from file: %w", err)
		}

		c, err := api.NewClient(nil)
		if err != nil {
			return nil, fmt.Errorf("creating vault client: %w", err)
		}
		c.SetToken(strings.TrimSpace(string(tokenBytes)))
		return c, nil
	} else {
		wc, err := workloadapi.New(ctx)
		if err != nil {
			return nil, fmt.Errorf("creating workload api client: %w", err)
		}
		defer wc.Close()

		source, err := workloadapi.NewX509Source(ctx, workloadapi.WithClient(wc))
		if err != nil {
			return nil, fmt.Errorf("creating x509 source: %w", err)
		}
		defer source.Close()

		serverID := spiffeid.RequireFromString("spiffe://home.mattmoriarity.com/svc/vault")

		vaultConfig := api.DefaultConfig()
		transport := vaultConfig.HttpClient.Transport.(*http.Transport)
		transport.TLSClientConfig = tlsconfig.TLSClientConfig(source, tlsconfig.AuthorizeID(serverID))

		c, err := api.NewClient(vaultConfig)
		if err != nil {
			return nil, fmt.Errorf("creating vault client: %w", err)
		}

		jwtSource, err := workloadapi.NewJWTSource(ctx)
		if err != nil {
			return nil, fmt.Errorf("creating jwt source: %w", err)
		}
		defer jwtSource.Close()

		svid, err := jwtSource.FetchJWTSVID(ctx, jwtsvid.Params{
			Audience: os.Getenv("VAULT_ADDR"),
		})
		if err != nil {
			return nil, fmt.Errorf("fetching jwt svid: %w", err)
		}

		req := map[string]any{
			"role": "spiffe",
			"jwt":  svid.Marshal(),
		}
		resp, err := c.Logical().WriteWithContext(ctx, "auth/spiffe/login", req)
		if err != nil {
			return nil, fmt.Errorf("authorizing vault with jwt token: %w", err)
		}

		c.SetToken(resp.Auth.ClientToken)
		return c, err
	}
}
