package main

import (
	"context"
	"fmt"
	"os"
	"path"

	"git.midna.dev/mjm/nix-config/packages/dippy/cmd"
	"git.midna.dev/mjm/nix-config/packages/dippy/nix"
	"git.midna.dev/mjm/nix-config/packages/dippy/vault"
	"github.com/hashicorp/vault/api"
	"golang.org/x/crypto/ssh"
	"golang.org/x/crypto/ssh/knownhosts"
)

type Config struct {
	Vault        *api.Client
	Nix          nix.Nix
	Runner       cmd.Runner
	RemoteRunner func(host, user string) (cmd.Runner, error)
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
		Vault:  c,
		Nix:    nix.New(keyPath),
		Runner: cmd.LocalRunner{},
		RemoteRunner: func(host, user string) (cmd.Runner, error) {
			return cmd.NewSSHRunner(host, user, signer, hostKeyCallback)
		},
		keyPath: keyPath,
	}, nil
}

func NewLocalConfig() (Config, error) {
	c, err := vault.NewClient(context.TODO())
	if err != nil {
		return Config{}, fmt.Errorf("creating vault client: %w", err)
	}

	return Config{
		Vault:  c,
		Nix:    nix.New(""),
		Runner: cmd.LocalRunner{},
		RemoteRunner: func(host, user string) (cmd.Runner, error) {
			return nil, fmt.Errorf("remote runner not supported in this config")
		},
	}, nil
}

func (c *Config) Cleanup() {
	if c.keyPath != "" {
		os.RemoveAll(path.Dir(c.keyPath))
	}
}
