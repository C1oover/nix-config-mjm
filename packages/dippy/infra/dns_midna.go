package infra

import (
	"fmt"

	"github.com/pulumi/pulumi-terraform-provider/sdks/go/desec/desec"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

const (
	ipv6Prefix = "2601:282:0:30e0"
	aion       = "5.78.46.61"
)

var ingressIPs = []string{
	ipv6Prefix + ":dea6:32ff:fed5:d840",
	ipv6Prefix + ":dea6:32ff:fe96:bc05",
}

func setUpMidnaDev(ctx *pulumi.Context, vhosts map[string]bool) error {
	d, err := desec.NewDomain(ctx, "midna.dev", &desec.DomainArgs{
		Name: pulumi.String("midna.dev"),
	}, pulumi.Import(pulumi.ID("midna.dev")))
	if err != nil {
		return err
	}

	if _, err := newMailRecords(ctx, "midna.dev", &MailRecordsArgs{
		Domain:   d,
		DmarcRUA: pulumi.String("dmarc-rua@mj.midna.dev"),
		DmarcRUF: pulumi.String("dmarc-ruf@mj.midna.dev"),
		SmtpRUA:  pulumi.String("tlsrpt@mj.midna.dev"),
	}); err != nil {
		return err
	}

	if _, err := newACMEChallenge(ctx, "midna.dev", d); err != nil {
		return err
	}

	// IPv6 ingress records
	if _, err := desec.NewRrset(ctx, "ingress.midna.dev_aaaa", &desec.RrsetArgs{
		Domain:  d.ID(),
		Subname: pulumi.String("ingress"),
		Type:    pulumi.String("AAAA"),
		Ttl:     pulumi.Float64(3600),
		Records: pulumi.ToStringArray(ingressIPs),
	}, pulumi.Import(pulumi.ID("midna.dev/ingress/AAAA"))); err != nil {
		return err
	}
	if _, err := desec.NewRrset(ctx, "ingress4.midna.dev_aaaa", &desec.RrsetArgs{
		Domain:  d.ID(),
		Subname: pulumi.String("ingress4"),
		Type:    pulumi.String("AAAA"),
		Ttl:     pulumi.Float64(3600),
		Records: pulumi.ToStringArray(ingressIPs),
	}, pulumi.Import(pulumi.ID("midna.dev/ingress4/AAAA"))); err != nil {
		return err
	}
	if _, err := desec.NewRrset(ctx, "midna.dev_aaaa", &desec.RrsetArgs{
		Domain:  d.ID(),
		Subname: pulumi.String(""),
		Type:    pulumi.String("AAAA"),
		Ttl:     pulumi.Float64(3600),
		Records: pulumi.ToStringArray(ingressIPs),
	}, pulumi.Import(pulumi.ID("midna.dev/@/AAAA"))); err != nil {
		return err
	}

	// IPv4 ingress records
	if _, err := desec.NewRrset(ctx, "ingress4.midna.dev_a", &desec.RrsetArgs{
		Domain:  d.ID(),
		Subname: pulumi.String("ingress4"),
		Type:    pulumi.String("A"),
		Ttl:     pulumi.Float64(3600),
		Records: pulumi.ToStringArray([]string{aion}),
	}, pulumi.Import(pulumi.ID("midna.dev/ingress4/A"))); err != nil {
		return err
	}
	if _, err := desec.NewRrset(ctx, "midna.dev_a", &desec.RrsetArgs{
		Domain:  d.ID(),
		Subname: pulumi.String(""),
		Type:    pulumi.String("A"),
		Ttl:     pulumi.Float64(3600),
		Records: pulumi.ToStringArray([]string{aion}),
	}, pulumi.Import(pulumi.ID("midna.dev/@/A"))); err != nil {
		return err
	}

	for name, ipv4 := range vhosts {
		args := &desec.RrsetArgs{
			Domain:  d.ID(),
			Subname: pulumi.String(name),
			Type:    pulumi.String("CNAME"),
			Ttl:     pulumi.Float64(3600),
		}
		cname := "ingress.midna.dev."
		if ipv4 {
			cname = "ingress4.midna.dev."
		}
		args.Records = pulumi.ToStringArray([]string{cname})

		if _, err := desec.NewRrset(ctx,
			fmt.Sprintf("%s.midna.dev", name), args,
			pulumi.Import(pulumi.ID(fmt.Sprintf("midna.dev/%s/CNAME", name))),
		); err != nil {
			return err
		}
	}

	if _, err := desec.NewRrset(ctx, "wildcard-pages.midna.dev", &desec.RrsetArgs{
		Domain:  d.ID(),
		Subname: pulumi.String("*.pages"),
		Type:    pulumi.String("CNAME"),
		Ttl:     pulumi.Float64(3600),
		Records: pulumi.ToStringArray([]string{"ingress4.midna.dev."}),
	}, pulumi.Import(pulumi.ID("midna.dev/*.pages/CNAME"))); err != nil {
		return err
	}

	if _, err := desec.NewRrset(ctx, "www.midna.dev", &desec.RrsetArgs{
		Domain:  d.ID(),
		Subname: pulumi.String("www"),
		Type:    pulumi.String("CNAME"),
		Ttl:     pulumi.Float64(3600),
		Records: pulumi.ToStringArray([]string{"ingress4.midna.dev."}),
	}, pulumi.Import(pulumi.ID("midna.dev/www/CNAME"))); err != nil {
		return err
	}
	if _, err := desec.NewRrset(ctx, "spiffe.midna.dev", &desec.RrsetArgs{
		Domain:  d.ID(),
		Subname: pulumi.String("spiffe"),
		Type:    pulumi.String("CNAME"),
		Ttl:     pulumi.Float64(3600),
		Records: pulumi.ToStringArray([]string{ "ingress.midna.dev."}),
	}); err != nil {
		return err
	}

	return nil
}
