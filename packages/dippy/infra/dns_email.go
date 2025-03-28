package infra

import (
	"fmt"

	"github.com/pulumi/pulumi-terraform-provider/sdks/go/desec/desec"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

type MailRecords struct {
	pulumi.ResourceState
}

type MailRecordsArgs struct {
	Domain   *desec.Domain
	DmarcRUA pulumi.StringInput
	DmarcRUF pulumi.StringInput
	SmtpRUA  pulumi.StringInput
}

func newMailRecords(ctx *pulumi.Context, name string, args *MailRecordsArgs, opts ...pulumi.ResourceOption) (*MailRecords, error) {
	mr := &MailRecords{}
	if err := ctx.RegisterComponentResource("dippy:MailRecords", name, mr, opts...); err != nil {
		return nil, err
	}

	if _, err := desec.NewRrset(ctx, fmt.Sprintf("%s-mta-sts_txt", name), &desec.RrsetArgs{
		Domain:  args.Domain.ID(),
		Subname: pulumi.String("_mta-sts"),
		Type:    pulumi.String("TXT"),
		Ttl:     pulumi.Float64(3600),
		Records: pulumi.ToStringArray([]string{
			"v=STSv1; id=20250328T162250Z",
		}),
	}, pulumi.Parent(mr)); err != nil {
		return nil, err
	}

	if _, err := desec.NewRrset(ctx, fmt.Sprintf("%s-mta-sts_cname", name), &desec.RrsetArgs{
		Domain:  args.Domain.ID(),
		Subname: pulumi.String("mta-sts"),
		Type:    pulumi.String("CNAME"),
		Ttl:     pulumi.Float64(3600),
		Records: pulumi.ToStringArray([]string{
			"ingress4.midna.dev.",
		}),
	}, pulumi.Parent(mr)); err != nil {
		return nil, err
	}

	mxRecords := []string{
		"10 in1-smtp.messagingengine.com.",
		"20 in2-smtp.messagingengine.com.",
	}

	if _, err := desec.NewRrset(ctx, fmt.Sprintf("%s-root_mx", name), &desec.RrsetArgs{
		Domain:  args.Domain.ID(),
		Subname: pulumi.String(""),
		Type:    pulumi.String("MX"),
		Ttl:     pulumi.Float64(3600),
		Records: pulumi.ToStringArray(mxRecords),
	}, pulumi.Parent(mr)); err != nil {
		return nil, err
	}

	if _, err := desec.NewRrset(ctx, fmt.Sprintf("%s-wildcard_mx", name), &desec.RrsetArgs{
		Domain:  args.Domain.ID(),
		Subname: pulumi.String("*"),
		Type:    pulumi.String("MX"),
		Ttl:     pulumi.Float64(3600),
		Records: pulumi.ToStringArray(mxRecords),
	}, pulumi.Parent(mr)); err != nil {
		return nil, err
	}

	if _, err := desec.NewRrset(ctx, fmt.Sprintf("%s-spf", name), &desec.RrsetArgs{
		Domain:  args.Domain.ID(),
		Subname: pulumi.String(""),
		Type:    pulumi.String("TXT"),
		Ttl:     pulumi.Float64(3600),
		Records: pulumi.ToStringArray([]string{
			"v=spf1 include:spf.messagingengine.com ~all",
		}),
	}, pulumi.Parent(mr)); err != nil {
		return nil, err
	}

	for i := 1; i <= 3; i++ {
		if _, err := desec.NewRrset(ctx, fmt.Sprintf("%s-fastmail-domainkey%d", name, i), &desec.RrsetArgs{
			Domain:  args.Domain.ID(),
			Subname: pulumi.Sprintf("fm%d._domainkey", i),
			Type:    pulumi.String("CNAME"),
			Ttl:     pulumi.Float64(3600),
			Records: pulumi.ToStringArray([]string{
				fmt.Sprintf("fm%d.%s.dkim.fmhosted.com.", i, name),
			}),
		}, pulumi.Parent(mr)); err != nil {
			return nil, err
		}
	}

	rufOutput := pulumi.String("").ToStringOutput()
	if args.DmarcRUF != nil {
		rufOutput = pulumi.Sprintf("; ruf=mailto:%s", args.DmarcRUF)
	}

	if _, err := desec.NewRrset(ctx, fmt.Sprintf("%s-dmarc", name), &desec.RrsetArgs{
		Domain:  args.Domain.ID(),
		Subname: pulumi.String("_dmarc"),
		Type:    pulumi.String("TXT"),
		Ttl:     pulumi.Float64(3600),
		Records: pulumi.ToStringArrayOutput([]pulumi.StringOutput{
			pulumi.Sprintf("v=DMARC1; p=reject; rua=mailto:%s%s", args.DmarcRUA, rufOutput),
		}),
	}, pulumi.Parent(mr)); err != nil {
		return nil, err
	}

	if _, err := desec.NewRrset(ctx, fmt.Sprintf("%s-smtp-tls", name), &desec.RrsetArgs{
		Domain:  args.Domain.ID(),
		Subname: pulumi.String("_smtp._tls"),
		Type:    pulumi.String("TXT"),
		Ttl:     pulumi.Float64(3600),
		Records: pulumi.ToStringArrayOutput([]pulumi.StringOutput{
			pulumi.Sprintf("v=TLSRPTv1; rua=mailto:%s", args.SmtpRUA),
		}),
	}, pulumi.Parent(mr)); err != nil {
		return nil, err
	}

	return mr, nil
}
