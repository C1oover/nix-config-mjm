package infra

import (
	"github.com/pulumi/pulumi-hcloud/sdk/go/hcloud"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func setUpAion(ctx *pulumi.Context) error {
	if _, err := hcloud.NewServer(ctx, "aion", &hcloud.ServerArgs{
		Name:              pulumi.String("aion"),
		ServerType:        pulumi.String("cpx11"),
		Location:          pulumi.String("hil"),
		Datacenter:        pulumi.String("hil-dc1"),
		Image:             pulumi.String("ubuntu-22.04"),
		DeleteProtection:  pulumi.Bool(true),
		RebuildProtection: pulumi.Bool(true),
	}, pulumi.Protect(true)); err != nil {
		return err
	}

	return nil
}
