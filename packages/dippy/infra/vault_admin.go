package infra

import (
	_ "embed"

	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault"
	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault/identity"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

//go:embed vault_admin.hcl
var adminPolicy string

func setUpVaultAdmin(ctx *pulumi.Context) (*identity.Group, error) {
	p, err := vault.NewPolicy(ctx, "admin", &vault.PolicyArgs{
		Name:   pulumi.String("admin"),
		Policy: pulumi.String(adminPolicy),
	})
	if err != nil {
		return nil, err
	}

	g, err := identity.NewGroup(ctx, "admins", &identity.GroupArgs{
		Name:     pulumi.String("admins"),
		Type:     pulumi.StringPtr("external"),
		Policies: pulumi.ToStringArrayOutput([]pulumi.StringOutput{p.Name}),
	})
	if err != nil {
		return nil, err
	}

	return g, nil
}
