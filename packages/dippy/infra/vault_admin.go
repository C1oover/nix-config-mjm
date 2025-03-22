package infra

import (
	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault"
	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault/identity"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

// TODO serialize this from actual structured data
const adminPolicy = `{"path":{"auth/*":{"capabilities":["create","read","update","delete","list","sudo"]},"identity/*":{"capabilities":["create","read","update","delete","list","sudo"]},"kv/*":{"capabilities":["create","read","update","delete","list","sudo"]},"ssh-client-signer/*":{"capabilities":["create","read","update","delete","list","sudo"]},"ssh-host-signer/*":{"capabilities":["create","read","update","delete","list","sudo"]},"sys/auth":{"capabilities":["read"]},"sys/auth/*":{"capabilities":["create","update","delete","sudo"]},"sys/health":{"capabilities":["read","sudo"]},"sys/leases/*":{"capabilities":["create","read","update","delete","list","sudo"]},"sys/mounts":{"capabilities":["read"]},"sys/mounts/*":{"capabilities":["create","read","update","delete","list","sudo"]},"sys/plugins/catalog/*":{"capabilities":["create","read","update","delete","list","sudo"]},"sys/policies/acl":{"capabilities":["list"]},"sys/policies/acl/*":{"capabilities":["create","read","update","delete","list","sudo"]}}}`

func setUpVaultAdmin(ctx *pulumi.Context) (*identity.Group, error) {
	p, err := vault.NewPolicy(ctx, "admin", &vault.PolicyArgs{
		Name:   pulumi.String("admin"),
		Policy: pulumi.String(adminPolicy),
	}, pulumi.Import(pulumi.ID("admin")))
	if err != nil {
		return nil, err
	}

	g, err := identity.NewGroup(ctx, "admins", &identity.GroupArgs{
		Name:     pulumi.String("admins"),
		Type:     pulumi.StringPtr("external"),
		Policies: pulumi.ToStringArrayOutput([]pulumi.StringOutput{p.Name}),
	}, pulumi.Import(pulumi.ID("c955ed04-8f35-4292-e932-066c0a09f7dc")))
	if err != nil {
		return nil, err
	}

	return g, nil
}
