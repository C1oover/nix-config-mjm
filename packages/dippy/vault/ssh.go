package vault

import (
	"context"
	"crypto"
	"crypto/ed25519"
	"fmt"

	"github.com/hashicorp/vault/api"
	"golang.org/x/crypto/ssh"
)

func GenerateSSHKey(ctx context.Context, c *api.Client) (*ssh.Certificate, crypto.PrivateKey, error) {
	pubKey, privKey, err := ed25519.GenerateKey(nil)
	if err != nil {
		return nil, nil, fmt.Errorf("generating new key: %w", err)
	}

	sshPubKey, err := ssh.NewPublicKey(pubKey)
	if err != nil {
		return nil, nil, fmt.Errorf("creating ssh public key: %w", err)
	}

	pubKeyBytes := ssh.MarshalAuthorizedKey(sshPubKey)

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
