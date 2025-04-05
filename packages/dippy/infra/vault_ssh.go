package infra

import (
	"time"

	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault"
	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault/ssh"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

const sshHostLeaseDuration = pulumi.Int(14 * 24 * time.Hour / time.Second)

func setUpVaultSSH(ctx *pulumi.Context) error {
	clientSigner, err := vault.NewMount(ctx, "ssh-client-signer", &vault.MountArgs{
		Type: pulumi.String("ssh"),
		Path: pulumi.String("ssh-client-signer"),
	}, pulumi.Protect(true))
	if err != nil {
		return err
	}

	if _, err := ssh.NewSecretBackendRole(ctx, "homelab-client", &ssh.SecretBackendRoleArgs{
		Backend:     clientSigner.Path,
		Name:        pulumi.String("homelab-client"),
		KeyType:     pulumi.String("ca"),
		Ttl:         pulumi.Sprintf("%d", 2*time.Hour/time.Second),
		DefaultUser: pulumi.String("matt"),
		DefaultExtensions: pulumi.StringMap{
			"permit-pty": pulumi.String(""),
		},
		AllowedExtensions:     pulumi.String("permit-pty"),
		AllowUserCertificates: pulumi.Bool(true),
		AllowedUsers:          pulumi.String("root,matt,mjm"),
	}, pulumi.Protect(true)); err != nil {
		return err
	}

	hostSigner, err := vault.NewMount(ctx, "ssh-host-signer", &vault.MountArgs{
		Type:               pulumi.String("ssh"),
		Path:               pulumi.String("ssh-host-signer"),
		MaxLeaseTtlSeconds: sshHostLeaseDuration,
	}, pulumi.Protect(true))
	if err != nil {
		return err
	}

	if _, err := ssh.NewSecretBackendRole(ctx, "homelab-host", &ssh.SecretBackendRoleArgs{
		Backend:               hostSigner.Path,
		Name:                  pulumi.String("homelab-host"),
		KeyType:               pulumi.String("ca"),
		Ttl:                   pulumi.Sprintf("%d", sshHostLeaseDuration),
		AllowHostCertificates: pulumi.Bool(true),
		AllowBareDomains:      pulumi.Bool(true),
		AllowSubdomains:       pulumi.Bool(true),
		AllowedDomains:        pulumi.String("home.mattmoriarity.com"),
	}, pulumi.Protect(true)); err != nil {
		return err
	}

	return nil
}
