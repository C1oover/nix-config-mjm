package infra

import (
	_ "embed"

	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault"
	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault/identity"
	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault/jwt"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

//go:embed vault_repo_nix_config.hcl
var nixConfigRepoPolicy string

func setUpVaultGitLab(ctx *pulumi.Context, spiffeBackend *jwt.AuthBackend) error {
	policy, err := vault.NewPolicy(ctx, "repo-nix-config", &vault.PolicyArgs{
		Name:   pulumi.String("repo-nix-config"),
		Policy: pulumi.String(nixConfigRepoPolicy),
	})
	if err != nil {
		return err
	}

	entity, err := identity.NewEntity(ctx, "repo-nix-config", &identity.EntityArgs{
		Name:     pulumi.String("repo: nix-config"),
		Policies: pulumi.StringArray{policy.Name},
	})
	if err != nil {
		return err
	}

	if _, err := identity.NewEntityAlias(ctx, "spiffe-repo-nix-config", &identity.EntityAliasArgs{
		Name:          pulumi.String("spiffe://home.mattmoriarity.com/ci/repo/nix-config"),
		CanonicalId:   entity.ID(),
		MountAccessor: spiffeBackend.Accessor,
	}); err != nil {
		return err
	}

	return nil
}
