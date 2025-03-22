package infra

import (
	"fmt"

	"github.com/pulumi/pulumi-terraform-provider/sdks/go/desec/desec"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

type ACMEChallenge struct {
	pulumi.ResourceState
}

func newACMEChallenge(ctx *pulumi.Context, name string, d *desec.Domain, opts ...pulumi.ResourceOption) (*ACMEChallenge, error) {
	ac := &ACMEChallenge{}
	if err := ctx.RegisterComponentResource("dippy:ACMEChallenge", name, ac, opts...); err != nil {
		return nil, err
	}

	challengeDomainName := d.Name.ApplyT(func(name string) string {
		return "_acme-challenge." + name
	}).(pulumi.StringOutput)

	acd, err := desec.NewDomain(ctx, fmt.Sprintf("%s-acme-challenge-domain", name), &desec.DomainArgs{
		Name: challengeDomainName,
	}, pulumi.Parent(ac))
	if err != nil {
		return nil, err
	}

	dsRecord := acd.Keys.Index(pulumi.Int(0)).Ds().Index(pulumi.Int(0))

	if _, err := desec.NewRrset(ctx, fmt.Sprintf("%s-acme-challenge-ds", name), &desec.RrsetArgs{
		Domain:  d.ID(),
		Subname: pulumi.String("_acme-challenge"),
		Type:    pulumi.String("DS"),
		Ttl:     pulumi.Float64(3600),
		Records: pulumi.ToStringArrayOutput([]pulumi.StringOutput{dsRecord}),
	}, pulumi.Parent(ac)); err != nil {
		return nil, err
	}

	if _, err := desec.NewRrset(ctx, fmt.Sprintf("%s-acme-challenge-ns", name), &desec.RrsetArgs{
		Domain:  d.ID(),
		Subname: pulumi.String("_acme-challenge"),
		Type:    pulumi.String("NS"),
		Ttl:     pulumi.Float64(3600),
		Records: pulumi.ToStringArray([]string{
			"ns1.desec.io.",
			"ns2.desec.org.",
		}),
	}, pulumi.Parent(ac)); err != nil {
		return nil, err
	}

	return ac, nil
}
