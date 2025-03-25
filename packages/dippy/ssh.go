package main

import (
	"crypto"
	"encoding/pem"
	"fmt"
	"os"
	"path"

	"golang.org/x/crypto/ssh"
)

func writeSSHKey(cert *ssh.Certificate, privKey crypto.PrivateKey) (string, error) {
	keyDir, err := os.MkdirTemp("", "dippy-keys")
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
