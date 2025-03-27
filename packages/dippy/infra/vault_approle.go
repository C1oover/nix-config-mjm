package infra

import (
	"encoding/json"
	"maps"

	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault"
	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault/approle"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func setUpVaultAppRoles(ctx *pulumi.Context, services map[string]map[string]any, policies map[string]string, roles map[string]RoleInput) error {
	backend, err := vault.NewAuthBackend(ctx, "approle", &vault.AuthBackendArgs{
		Type:           pulumi.String("approle"),
		Path:           pulumi.String("approle"),
		DisableRemount: pulumi.Bool(false),
	})
	if err != nil {
		return err
	}

	svcs := map[string]*VaultService{}
	for name, paths := range services {
		s, err := newVaultService(ctx, name, &VaultServiceArgs{
			Paths: pulumi.ToMap(paths),
		})
		if err != nil {
			return err
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
			return err
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
		_, err := approle.NewAuthBackendRole(ctx, name, &approle.AuthBackendRoleArgs{
			Backend:       backend.ID(),
			RoleName:      pulumi.String(name),
			TokenPolicies: tokenPolicies,
		})
		if err != nil {
			return err
		}
	}

	return nil
}

type VaultService struct {
	pulumi.ResourceState

	PolicyName pulumi.StringOutput
}

type VaultServiceArgs struct {
	Paths pulumi.MapInput
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

	ctx.RegisterResourceOutputs(vs, pulumi.Map{
		"policyName": p.Name,
	})
	vs.PolicyName = p.Name
	return vs, nil
}
