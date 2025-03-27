package infra

import (
	"encoding/json"

	"github.com/pulumi/pulumi-random/sdk/v4/go/random"
	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault"
	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault/kv"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func setUpHomeAssistantOIDC(ctx *pulumi.Context, kvMount *vault.Mount) error {
	oidcClientID, err := random.NewRandomString(ctx, "hass-oidc-client-id", &random.RandomStringArgs{
		Length:  pulumi.Int(64),
		Special: pulumi.Bool(false),
	})
	if err != nil {
		return err
	}
	ctx.Export("hassOidcClientID", oidcClientID.Result)

	oidcClientSecret, err := random.NewRandomBytes(ctx, "hass-oidc-client-secret", &random.RandomBytesArgs{
		Length: pulumi.Int(64),
	})
	if err != nil {
		return err
	}
	ctx.Export("hassOidcClientSecret", oidcClientSecret.Hex)

	data := oidcClientSecret.Hex.ApplyT(func(s string) (string, error) {
		d, err := json.Marshal(map[string]string{
			"oidc_client_secret": s,
		})
		if err != nil {
			return "", err
		}
		return string(d), nil
	}).(pulumi.StringOutput)

	kv.NewSecretV2(ctx, "hass-managed", &kv.SecretV2Args{
		Mount:    kvMount.Path,
		Name:     pulumi.String("prod/services/home-assistant/managed"),
		DataJson: data,
	})

	return nil
}
