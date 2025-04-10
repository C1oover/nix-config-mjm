package main

import (
	"context"
	"fmt"
	"os"
	"path"
	"sync"

	"git.midna.dev/mjm/nix-config/packages/dippy/cmd"
	"git.midna.dev/mjm/nix-config/packages/dippy/nix"
	"git.midna.dev/mjm/nix-config/packages/dippy/vault"
	"github.com/hashicorp/vault/api"
	"golang.org/x/crypto/ssh"
	"golang.org/x/crypto/ssh/knownhosts"
)

type Config struct {
	Nix          nix.Nix
	Runner       cmd.Runner
	RemoteRunner func(host, user string) (cmd.Runner, error)
	vaultLock    sync.Mutex
	vault        *api.Client
	vaultSecret  *api.KVSecret
	keyPath      string
}

func GenerateConfig(ctx context.Context) (Config, error) {
	c, err := vault.NewClient(ctx)
	if err != nil {
		return Config{}, fmt.Errorf("creating vault client: %w", err)
	}

	cert, privKey, err := vault.GenerateSSHKey(ctx, c)
	if err != nil {
		return Config{}, fmt.Errorf("generating ssh key: %w", err)
	}

	privKeySigner, err := ssh.NewSignerFromKey(privKey)
	if err != nil {
		return Config{}, fmt.Errorf("creating private key signer: %w", err)
	}

	signer, err := ssh.NewCertSigner(cert, privKeySigner)
	if err != nil {
		return Config{}, fmt.Errorf("creating cert signer: %w", err)
	}

	keyPath, err := writeSSHKey(cert, privKey)
	if err != nil {
		return Config{}, fmt.Errorf("writing ssh key: %w", err)
	}

	hostKeyCallback, err := knownhosts.New("/etc/ssh/ssh_known_hosts")
	if err != nil {
		return Config{}, fmt.Errorf("reading ssh known hosts: %w", err)
	}

	return Config{
		Nix:    nix.New(keyPath),
		Runner: cmd.LocalRunner{},
		RemoteRunner: func(host, user string) (cmd.Runner, error) {
			return cmd.NewSSHRunner(host, user, signer, hostKeyCallback)
		},
		vault:   c,
		keyPath: keyPath,
	}, nil
}

func NewLocalConfig() (Config, error) {
	return Config{
		Nix:    nix.New(""),
		Runner: cmd.LocalRunner{},
		RemoteRunner: func(host, user string) (cmd.Runner, error) {
			return nil, fmt.Errorf("remote runner not supported in this config")
		},
	}, nil
}

func (c *Config) Vault(ctx context.Context) (*api.Client, error) {
	c.vaultLock.Lock()
	defer c.vaultLock.Unlock()

	return c.getVaultClient(ctx)
}

func (c *Config) GetSecret(ctx context.Context, key string) (string, error) {
	c.vaultLock.Lock()
	defer c.vaultLock.Unlock()

	if c.vaultSecret == nil {
		client, err := c.getVaultClient(ctx)
		if err != nil {
			return "", fmt.Errorf("getting vault client: %w", err)
		}

		c.vaultSecret, err = client.KVv2("kv").Get(ctx, "prod/repos/nix-config")
		if err != nil {
			return "", fmt.Errorf("getting nix-config kv secret from vault: %w", err)
		}
	}

	return c.vaultSecret.Data[key].(string), nil
}

func (c *Config) getVaultClient(ctx context.Context) (*api.Client, error) {
	var err error
	if c.vault == nil {
		c.vault, err = vault.NewClient(ctx)
		if err != nil {
			return nil, fmt.Errorf("creating vault client to read secret: %w", err)
		}
	}

	return c.vault, nil
}

func (c *Config) Cleanup() {
	if c.keyPath != "" {
		os.RemoveAll(path.Dir(c.keyPath))
	}
}
