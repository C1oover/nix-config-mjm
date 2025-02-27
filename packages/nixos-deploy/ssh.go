package main

import (
	"context"
	"crypto"
	"crypto/ed25519"
	"encoding/pem"
	"fmt"
	"os"
	"path"
	"strings"

	"github.com/hashicorp/vault/api"
	"golang.org/x/crypto/ssh"
)

func newVaultClient(ctx context.Context) (*api.Client, error) {
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

func generateSSHKey(ctx context.Context) (*ssh.Certificate, crypto.PrivateKey, error) {
	pubKey, privKey, err := ed25519.GenerateKey(nil)
	if err != nil {
		return nil, nil, fmt.Errorf("generating new key: %w", err)
	}

	sshPubKey, err := ssh.NewPublicKey(pubKey)
	if err != nil {
		return nil, nil, fmt.Errorf("creating ssh public key: %w", err)
	}

	pubKeyBytes := ssh.MarshalAuthorizedKey(sshPubKey)

	c, err := newVaultClient(ctx)
	if err != nil {
		return nil, nil, fmt.Errorf("creating vault client: %w", err)
	}

	sshEngine := c.SSHWithMountPoint("ssh-client-signer")

	secret, err := sshEngine.SignKeyWithContext(ctx, "homelab-client", map[string]any{
		"public_key":       string(pubKeyBytes),
		"valid_principals": "matt,mjm",
	})
	if err != nil {
		return nil, nil, fmt.Errorf("signing ssh key: %w", err)
	}

	parsedCert, _, _, _, err := ssh.ParseAuthorizedKey([]byte(secret.Data["signed_key"].(string)))
	if err != nil {
		return nil, nil, fmt.Errorf("parsing ssh cert from vault: %w", err)
	}

	return parsedCert.(*ssh.Certificate), privKey, nil
}

func writeSSHKey(cert *ssh.Certificate, privKey crypto.PrivateKey) (string, error) {
	keyDir, err := os.MkdirTemp("", "nixos-deploy-keys")
	if err != nil {
		return "", fmt.Errorf("creating temp dir for keys: %w", err)
	}

	privBlock, err := ssh.MarshalPrivateKey(privKey, "")
	if err != nil {
		return "", fmt.Errorf("marshalling private key: %w", err)
	}

	privKeyData := pem.EncodeToMemory(privBlock)
	privKeyPath := path.Join(keyDir, "id_ed25519")
	if err := os.WriteFile(privKeyPath, privKeyData, 0600); err != nil {
		return "", fmt.Errorf("writing private key: %w", err)
	}

	certData := ssh.MarshalAuthorizedKey(cert)
	certPath := path.Join(keyDir, "id_ed25519-cert.pub")
	if err := os.WriteFile(certPath, certData, 0600); err != nil {
		return "", fmt.Errorf("writing certificate: %w", err)
	}

	return privKeyPath, nil
}
