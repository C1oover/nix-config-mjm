package infra

import (
	"github.com/pulumi/pulumi-random/sdk/v4/go/random"
	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault/identity"
	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault/jwt"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func setUpAuthOIDC(ctx *pulumi.Context, adminGroup *identity.Group) error {
	oidcClientID, err := random.NewRandomString(ctx, "vault-oidc-client-id", &random.RandomStringArgs{
		Length:  pulumi.Int(64),
		Special: pulumi.Bool(false),
	})
	if err != nil {
		return err
	}
	ctx.Export("vaultOidcClientID", oidcClientID.Result)

	oidcClientSecret, err := random.NewRandomBytes(ctx, "vault-oidc-client-secret", &random.RandomBytesArgs{
		Length: pulumi.Int(64),
	})
	if err != nil {
		return err
	}
	ctx.Export("vaultOidcClientSecret", oidcClientSecret.Hex)

	backend, err := jwt.NewAuthBackend(ctx, "oidc", &jwt.AuthBackendArgs{
		Path:             pulumi.String("oidc"),
		Type:             pulumi.String("oidc"),
		OidcDiscoveryUrl: pulumi.String("https://auth.midna.dev"),
		OidcClientId:     oidcClientID.Result,
		OidcClientSecret: oidcClientSecret.Hex,
		DefaultRole:      pulumi.String("default"),
		Tune: &jwt.AuthBackendTuneArgs{
			DefaultLeaseTtl: pulumi.String("768h"),
			MaxLeaseTtl:     pulumi.String("768h"),
			TokenType:       pulumi.String("default-service"),
		},
	}, pulumi.Protect(true))
	if err != nil {
		return err
	}

	if _, err := jwt.NewAuthBackendRole(ctx, "default", &jwt.AuthBackendRoleArgs{
		Backend:     backend.Path,
		RoleName:    pulumi.String("default"),
		UserClaim:   pulumi.String("preferred_username"),
		GroupsClaim: pulumi.String("groups"),
		OidcScopes: pulumi.ToStringArray([]string{
			"groups", "email", "profile",
		}),
		AllowedRedirectUris: pulumi.ToStringArray([]string{
			"https://vault.midna.dev/oidc/callback",
			"https://vault.midna.dev/ui/vault/auth/oidc/oidc/callback",
			"http://localhost:8250/oidc/callback",
		}),
	}); err != nil {
		return err
	}

	if _, err := identity.NewGroupAlias(ctx, "oidc-admins", &identity.GroupAliasArgs{
		Name:          pulumi.String("admins"),
		MountAccessor: backend.Accessor,
		CanonicalId:   adminGroup.ID(),
	}); err != nil {
		return err
	}

	return nil
}
