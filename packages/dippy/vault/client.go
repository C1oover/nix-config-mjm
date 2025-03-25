package vault

import (
	"context"
	"fmt"
	"os"
	"path"
	"strings"

	"github.com/hashicorp/vault/api"
)

func NewClient(ctx context.Context) (*api.Client, error) {
	c, err := api.NewClient(nil)
	if err != nil {
		return nil, fmt.Errorf("creating vault client: %w", err)
	}

	idToken := os.Getenv("VAULT_ID_TOKEN")
	if idToken == "" {
		// if no id token for jwt auth, assume this is called from somewhere where the
		// vault cli is being used, and try to read the token it stores
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return nil, fmt.Errorf("getting user home dir: %w", err)
		}

		tokenBytes, err := os.ReadFile(path.Join(homeDir, ".vault-token"))
		if err != nil {
			return nil, fmt.Errorf("reading vault token from file: %w", err)
		}

		c.SetToken(strings.TrimSpace(string(tokenBytes)))
	} else {
		req := map[string]any{
			"role": "homelab-infra",
			"jwt":  idToken,
		}
		resp, err := c.Logical().WriteWithContext(ctx, "auth/gitlab/login", req)
		if err != nil {
			return nil, fmt.Errorf("authorizing vault with jwt token: %w", err)
		}

		c.SetToken(resp.Auth.ClientToken)
	}

	return c, nil
}
