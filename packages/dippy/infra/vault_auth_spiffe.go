package infra

import (
	_ "embed"

	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault"
	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault/identity"
	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault/jwt"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

//go:embed service.hcl
var servicePolicy string

//go:embed sshd.hcl
var sshdPolicy string

//go:embed vault-backup.hcl
var vaultBackupPolicy string

func setUpAuthSPIFFE(
	ctx *pulumi.Context,
	services map[string]struct{},
	roles map[string]struct{},
) (*jwt.AuthBackend, error) {
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
			pulumi.String("https://vault.service.consul:8200"),
		},
	}); err != nil {
		return nil, err
	}

	servicePolicy, err := vault.NewPolicy(ctx, "service", &vault.PolicyArgs{
		Name:   pulumi.String("service"),
		Policy: pulumi.String(servicePolicy),
	})
	if err != nil {
		return nil, err
	}

	sshdPolicy, err := vault.NewPolicy(ctx, "sshd", &vault.PolicyArgs{
		Name:   pulumi.String("sshd"),
		Policy: pulumi.String(sshdPolicy),
	})
	if err != nil {
		return nil, err
	}

	vaultBackupPolicy, err := vault.NewPolicy(ctx, "vault-backup", &vault.PolicyArgs{
		Name:   pulumi.String("vault-backup"),
		Policy: pulumi.String(vaultBackupPolicy),
	})
	if err != nil {
		return nil, err
	}

	for name := range services {
		// TODO get this information from the Nix side
		var extraPolicies []*vault.Policy
		if name == "vault" {
			extraPolicies = []*vault.Policy{vaultBackupPolicy}
		}

		if _, err := newVaultService(ctx, name, &VaultServiceArgs{
			SPIFFEBackend: backend,
			ServicePolicy: servicePolicy,
			ExtraPolicies: extraPolicies,
		}); err != nil {
			return nil, err
		}
	}

	for name := range roles {
		sshdEntity, err := identity.NewEntity(ctx, "host-sshd-"+name, &identity.EntityArgs{
			Name:     pulumi.Sprintf("sshd: %s", name),
			Policies: pulumi.StringArray{sshdPolicy.Name},
			Metadata: pulumi.StringMap{
				"hostname": pulumi.String(name),
				"domain":   pulumi.String("home.mattmoriarity.com"),
				"fqdn":     pulumi.Sprintf("%s.home.mattmoriarity.com", name),
			},
		})
		if err != nil {
			return nil, err
		}

		if _, err := identity.NewEntityAlias(ctx, "spiffe-host-sshd-"+name, &identity.EntityAliasArgs{
			Name:          pulumi.Sprintf("spiffe://home.mattmoriarity.com/%s/sshd", name),
			CanonicalId:   sshdEntity.ID(),
			MountAccessor: backend.Accessor,
		}); err != nil {
			return nil, err
		}
	}

	return backend, nil
}

type VaultService struct {
	pulumi.ResourceState
}

type VaultServiceArgs struct {
	SPIFFEBackend *jwt.AuthBackend
	ServicePolicy *vault.Policy
	ExtraPolicies []*vault.Policy
}

func newVaultService(ctx *pulumi.Context, name string, args *VaultServiceArgs, opts ...pulumi.ResourceOption) (*VaultService, error) {
	vs := &VaultService{}
	if err := ctx.RegisterComponentResource("dippy:index/vault:Service", name, vs, opts...); err != nil {
		return nil, err
	}

	svcPolicies := pulumi.StringArray{args.ServicePolicy.Name}
	for _, p := range args.ExtraPolicies {
		svcPolicies = append(svcPolicies, p.Name)
	}

	entity, err := identity.NewEntity(ctx, "service-"+name, &identity.EntityArgs{
		Name:     pulumi.Sprintf("service: %s", name),
		Policies: svcPolicies,
		Metadata: pulumi.StringMap{
			"service": pulumi.String(name),
		},
	}, pulumi.Parent(vs))
	if err != nil {
		return nil, err
	}

	if _, err := identity.NewEntityAlias(ctx, "spiffe-service-"+name, &identity.EntityAliasArgs{
		Name:          pulumi.Sprintf("spiffe://home.mattmoriarity.com/svc/%s", name),
		CanonicalId:   entity.ID(),
		MountAccessor: args.SPIFFEBackend.Accessor,
	}, pulumi.Parent(vs)); err != nil {
		return nil, err
	}

	ctx.RegisterResourceOutputs(vs, pulumi.Map{})
	return vs, nil
}
