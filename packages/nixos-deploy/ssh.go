package main

import (
	"context"
	"crypto/ed25519"
	"encoding/pem"
	"fmt"
	"log/slog"
	"os"
	"path"

	"github.com/hashicorp/vault/api"
	"golang.org/x/crypto/ssh"
)

func generateSSHKey(ctx context.Context) ([]byte, []byte, error) {
	pubKey, privKey, err := ed25519.GenerateKey(nil)
	if err != nil {
		return nil, nil, fmt.Errorf("generating new key: %w", err)
	}

	sshPubKey, err := ssh.NewPublicKey(pubKey)
	if err != nil {
		return nil, nil, fmt.Errorf("creating ssh public key: %w", err)
	}

	pubKeyBytes := ssh.MarshalAuthorizedKey(sshPubKey)

	c, err := api.NewClient(nil)
	if err != nil {
		return nil, nil, fmt.Errorf("creating vault client: %w", err)
	}

	sshEngine := c.SSHWithMountPoint("ssh-client-signer")

	secret, err := sshEngine.SignKeyWithContext(ctx, "homelab-client", map[string]interface{}{
		"public_key":       string(pubKeyBytes),
		"valid_principals": "matt,mjm",
	})
	if err != nil {
		return nil, nil, fmt.Errorf("signing ssh key: %w", err)
	}

	privBlock, err := ssh.MarshalPrivateKey(privKey, "")
	if err != nil {
		return nil, nil, fmt.Errorf("marshalling private key: %w", err)
	}

	return []byte(secret.Data["signed_key"].(string)), pem.EncodeToMemory(privBlock), nil
}

func generateAndWriteSSHKey(ctx context.Context) (string, error) {
	cert, privKey, err := generateSSHKey(ctx)
	if err != nil {
		return "", err
	}

	keyDir, err := os.MkdirTemp("", "nixos-deploy-keys")
	if err != nil {
		return "", fmt.Errorf("creating temp dir for keys: %w", err)
	}

	privKeyPath := path.Join(keyDir, "id_ed25519")
	if err := os.WriteFile(privKeyPath, privKey, 0600); err != nil {
		return "", fmt.Errorf("writing private key: %w", err)
	}

	certPath := path.Join(keyDir, "id_ed25519-cert.pub")
	if err := os.WriteFile(certPath, cert, 0600); err != nil {
		return "", fmt.Errorf("writing certificate: %w", err)
	}

	slog.InfoContext(ctx, "generated ssh key and cert", "cert", certPath)
	return privKeyPath, nil
}
