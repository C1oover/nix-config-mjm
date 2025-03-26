package infra

import (
	_ "embed"

	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault"
	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault/jwt"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

//go:embed vault_repo_nix_config.hcl
var nixConfigRepoPolicy string

func setUpVaultGitLab(ctx *pulumi.Context) error {
	backend, err := jwt.NewAuthBackend(ctx, "gitlab", &jwt.AuthBackendArgs{
		Path:        pulumi.String("gitlab"),
		BoundIssuer: pulumi.String("https://git.midna.dev"),
		JwksUrl:     pulumi.String("https://git.midna.dev/oauth/discovery/keys"),
		Tune: jwt.AuthBackendTuneArgs{
			DefaultLeaseTtl:   pulumi.String("2h"),
			MaxLeaseTtl:       pulumi.String("2h"),
			TokenType:         pulumi.String("default-service"),
			ListingVisibility: pulumi.String("hidden"),
		},
	})
	if err != nil {
		return err
	}

	policy, err := vault.NewPolicy(ctx, "repo-nix-config", &vault.PolicyArgs{
		Name:   pulumi.String("repo-nix-config"),
		Policy: pulumi.String(nixConfigRepoPolicy),
	})
	if err != nil {
		return err
	}

	if _, err := jwt.NewAuthBackendRole(ctx, "gitlab-nix-config", &jwt.AuthBackendRoleArgs{
		Backend:       backend.Path,
		RoleName:      pulumi.String("homelab-infra"),
		RoleType:      pulumi.String("jwt"),
		UserClaim:     pulumi.String("user_email"),
		TokenPolicies: pulumi.StringArray{policy.Name},
		BoundAudiences: pulumi.StringArray{
			pulumi.String("http://vault.service.consul:8200"),
		},
		BoundClaims: pulumi.StringMap{"project_id": pulumi.String("30")},
	}); err != nil {
		return err
	}

	return nil
}
