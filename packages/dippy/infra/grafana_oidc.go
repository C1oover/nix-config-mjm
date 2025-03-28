package infra

import (
	"encoding/json"

	"github.com/pulumi/pulumi-random/sdk/v4/go/random"
	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault"
	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault/kv"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func setUpGrafanaOIDC(ctx *pulumi.Context, kvMount *vault.Mount) error {
	oidcClientID, err := random.NewRandomString(ctx, "grafana-oidc-client-id", &random.RandomStringArgs{
		Length:  pulumi.Int(64),
		Special: pulumi.Bool(false),
	})
	if err != nil {
		return err
	}
	ctx.Export("grafanaOidcClientID", oidcClientID.Result)

	oidcClientSecret, err := random.NewRandomBytes(ctx, "grafana-oidc-client-secret", &random.RandomBytesArgs{
		Length: pulumi.Int(64),
	})
	if err != nil {
		return err
	}
	ctx.Export("grafanaOidcClientSecret", oidcClientSecret.Hex)

	data := oidcClientSecret.Hex.ApplyT(func(s string) (string, error) {
		d, err := json.Marshal(map[string]string{
			"oidc_client_secret": s,
		})
		if err != nil {
			return "", err
		}
		return string(d), nil
	}).(pulumi.StringOutput)

	if _, err := kv.NewSecretV2(ctx, "grafana-managed", &kv.SecretV2Args{
		Mount:    kvMount.Path,
		Name:     pulumi.String("prod/services/grafana/managed"),
		DataJson: data,
	}); err != nil {
		return err
	}

	return nil
}
