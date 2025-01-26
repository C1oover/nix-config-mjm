package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"path"

	"git.midna.dev/mjm/nix-config/packages/nixos-deploy/cmd"
	"golang.org/x/crypto/ssh"
	"golang.org/x/crypto/ssh/knownhosts"
)

type Config struct {
	Runner       cmd.Runner
	RemoteRunner func(host, user string) (cmd.Runner, error)
	SSHOpts      []string
	keyPath      string
}

func GenerateConfig(ctx context.Context) (Config, error) {
	cert, privKey, err := generateSSHKey(ctx)
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

	args := []string{
		"-o",
		"BatchMode=yes",
		"-T",
	}

	args = append(args, "-o", fmt.Sprintf("IdentityFile=%s", keyPath))
	slog.Debug("ssh options", "opts", args)

	hostKeyCallback, err := knownhosts.New("/etc/ssh/ssh_known_hosts")
	if err != nil {
		return Config{}, fmt.Errorf("reading ssh known hosts: %w", err)
	}

	return Config{
		Runner: cmd.LocalRunner{},
		RemoteRunner: func(host, user string) (cmd.Runner, error) {
			return cmd.NewSSHRunner(host, user, signer, hostKeyCallback)
		},
		SSHOpts: args,
		keyPath: keyPath,
	}, nil
}

func NewLocalConfig() Config {
	return Config{
		Runner: cmd.LocalRunner{},
		RemoteRunner: func(host, user string) (cmd.Runner, error) {
			return nil, fmt.Errorf("remote runner not supported in this config")
		},
	}
}

func (c *Config) Cleanup() {
	if c.keyPath != "" {
		os.RemoveAll(path.Dir(c.keyPath))
	}
}
