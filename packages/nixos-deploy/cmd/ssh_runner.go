package cmd

import (
	"context"
	"fmt"
	"os"
	"strings"

	"golang.org/x/crypto/ssh"
)

type SSHRunner struct {
	client *ssh.Client
}

func NewSSHRunner(host string, user string, key ssh.Signer, hostKeyCallback ssh.HostKeyCallback) (*SSHRunner, error) {
	config := &ssh.ClientConfig{
		User: user,
		Auth: []ssh.AuthMethod{
			ssh.PublicKeys(key),
		},
		HostKeyCallback: hostKeyCallback,
		HostKeyAlgorithms: []string{
			ssh.CertAlgoED25519v01,
			ssh.KeyAlgoED25519,
			ssh.KeyAlgoRSA,
		},
	}

	client, err := ssh.Dial("tcp", host+":22", config)
	if err != nil {
		return nil, fmt.Errorf("dialing %s via ssh: %w", host, err)
	}

	return &SSHRunner{client: client}, nil
}

func (r *SSHRunner) Execute(ctx context.Context, name string, args ...string) error {
	session, err := r.client.NewSession()
	if err != nil {
		return fmt.Errorf("creating ssh session: %w", err)
	}
	defer session.Close()

	session.Stdout = os.Stdout
	session.Stderr = os.Stderr

	// TODO better shell escaping?
	return session.Run(name + " " + strings.Join(args, " "))
}

func (r *SSHRunner) ExecuteOutput(ctx context.Context, name string, args ...string) ([]byte, error) {
	session, err := r.client.NewSession()
	if err != nil {
		return nil, fmt.Errorf("creating ssh session: %w", err)
	}
	defer session.Close()

	session.Stderr = os.Stderr

	// TODO better shell escaping?
	return session.Output(name + " " + strings.Join(args, " "))
}
