package infra

import (
	"github.com/pulumi/pulumi-terraform-provider/sdks/go/desec/desec"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func setUpMattmoriarityCom(ctx *pulumi.Context) error {
	d, err := desec.NewDomain(ctx, "mattmoriarity.com", &desec.DomainArgs{
		Name: pulumi.String("mattmoriarity.com"),
	})
	if err != nil {
		return err
	}

	if _, err := newMailRecords(ctx, "mattmoriarity.com", &MailRecordsArgs{
		Domain:   d,
		DmarcRUA: pulumi.String("7be06458@in.mailhardener.com"),
		SmtpRUA:  pulumi.String("7be06458@in.mailhardener.com"),
	}); err != nil {
		return err
	}

	if _, err := newACMEChallenge(ctx, "mattmoriarity.com", d); err != nil {
		return err
	}

	return nil
}
