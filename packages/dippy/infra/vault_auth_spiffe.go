package infra

import (
	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault/jwt"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func setUpAuthSPIFFE(ctx *pulumi.Context) (*jwt.AuthBackend, error) {
	backend, err := jwt.NewAuthBackend(ctx, "spiffe", &jwt.AuthBackendArgs{
		Path:             pulumi.String("spiffe"),
		Type:             pulumi.String("jwt"),
		OidcDiscoveryUrl: pulumi.String("https://spiffe.midna.dev"),
	})
	if err != nil {
		return nil, err
	}

	if _, err := jwt.NewAuthBackendRole(ctx, "spiffe", &jwt.AuthBackendRoleArgs{
		Backend:   backend.Path,
		RoleName:  pulumi.String("spiffe"),
		RoleType:  pulumi.String("jwt"),
		UserClaim: pulumi.String("sub"),
		BoundAudiences: pulumi.StringArray{
			pulumi.String("https://vault.service.consul:8250"),
			pulumi.String("https://vault.service.consul:8200"),
		},
	}); err != nil {
		return nil, err
	}

	return backend, nil
}
