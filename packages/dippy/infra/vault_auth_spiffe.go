package infra

import (
	_ "embed"
	"encoding/json"
	"maps"

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
	services map[string]map[string]any,
	policies map[string]string,
	roles map[string]RoleInput,
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

	svcs := map[string]*VaultService{}
	for name, paths := range services {
		// TODO get this information from the Nix side
		var extraPolicies []*vault.Policy
		if name == "vault" {
			extraPolicies = []*vault.Policy{vaultBackupPolicy}
		}

		s, err := newVaultService(ctx, name, &VaultServiceArgs{
			SPIFFEBackend: backend,
			ServicePolicy: servicePolicy,
			Paths:         pulumi.ToMap(paths),
			ExtraPolicies: extraPolicies,
		})
		if err != nil {
			return nil, err
		}

		svcs[name] = s
	}

	pols := map[string]*vault.Policy{}
	for name, policy := range policies {
		p, err := vault.NewPolicy(ctx, name, &vault.PolicyArgs{
			Name:   pulumi.String(name),
			Policy: pulumi.String(policy),
		})
		if err != nil {
			return nil, err
		}

		pols[name] = p
	}

	for name, r := range roles {
		var tokenPolicies pulumi.StringArray
		for _, pname := range r.Policies {
			p := pols[pname]
			tokenPolicies = append(tokenPolicies, p.Name)
		}
		for _, sname := range r.Services {
			s := svcs[sname]
			tokenPolicies = append(tokenPolicies, s.PolicyName)
		}

		entity, err := identity.NewEntity(ctx, "host-"+name, &identity.EntityArgs{
			Name:     pulumi.Sprintf("host: %s", name),
			Policies: tokenPolicies,
			Metadata: pulumi.StringMap{
				"hostname": pulumi.String(name),
				"domain":   pulumi.String("home.mattmoriarity.com"),
				"fqdn":     pulumi.Sprintf("%s.home.mattmoriarity.com", name),
			},
		})
		if err != nil {
			return nil, err
		}

		if _, err := identity.NewEntityAlias(ctx, "spiffe-host-"+name, &identity.EntityAliasArgs{
			Name:          pulumi.Sprintf("spiffe://home.mattmoriarity.com/%s/vault-secrets", name),
			CanonicalId:   entity.ID(),
			MountAccessor: backend.Accessor,
		}); err != nil {
			return nil, err
		}

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

	PolicyName pulumi.StringOutput
}

type VaultServiceArgs struct {
	SPIFFEBackend *jwt.AuthBackend
	ServicePolicy *vault.Policy
	Paths         pulumi.MapInput
	ExtraPolicies []*vault.Policy
}

func newVaultService(ctx *pulumi.Context, name string, args *VaultServiceArgs, opts ...pulumi.ResourceOption) (*VaultService, error) {
	vs := &VaultService{}
	if err := ctx.RegisterComponentResource("dippy:index/vault:Service", name, vs, opts...); err != nil {
		return nil, err
	}

	policy := args.Paths.ToMapOutput().ApplyT(func(paths map[string]any) (string, error) {
		paths = maps.Clone(paths)
		paths["kv/data/prod/services/"+name] = map[string][]string{"capabilities": {"read"}}
		paths["kv/data/prod/services/"+name+"/*"] = map[string][]string{"capabilities": {"read"}}
		data := map[string]any{"path": paths}

		b, err := json.Marshal(data)
		if err != nil {
			return "", err
		}

		return string(b), nil
	}).(pulumi.StringOutput)

	p, err := vault.NewPolicy(ctx, "service-"+name, &vault.PolicyArgs{
		Name:   pulumi.Sprintf("service-%s", name),
		Policy: policy,
	}, pulumi.Parent(vs))
	if err != nil {
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

	ctx.RegisterResourceOutputs(vs, pulumi.Map{
		"policyName": p.Name,
	})
	vs.PolicyName = p.Name
	return vs, nil
}
