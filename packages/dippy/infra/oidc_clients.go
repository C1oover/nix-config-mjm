package infra

import (
	"encoding/json"

	"github.com/pulumi/pulumi-random/sdk/v4/go/random"
	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault"
	"github.com/pulumi/pulumi-vault/sdk/v6/go/vault/kv"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

type oidcClient struct {
	ClientID     pulumi.StringOutput
	ClientSecret pulumi.StringOutput
}

func setUpOIDC(ctx *pulumi.Context, clientNames []string, kvMount *vault.Mount) (map[string]oidcClient, error) {
	clients := map[string]oidcClient{}

	for _, name := range clientNames {
		clientID, err := random.NewRandomString(ctx, name+"-oidc-client-id", &random.RandomStringArgs{
			Length:  pulumi.Int(64),
			Special: pulumi.Bool(false),
		})
		if err != nil {
			return nil, err
		}
		ctx.Export(name+"OidcClientID", clientID.Result)

		clientSecret, err := random.NewRandomBytes(ctx, name+"-oidc-client-secret", &random.RandomBytesArgs{
			Length: pulumi.Int(64),
		})
		if err != nil {
			return nil, err
		}
		ctx.Export(name+"OidcClientSecret", clientSecret.Hex)

		clients[name] = oidcClient{
			ClientID:     clientID.Result,
			ClientSecret: clientSecret.Hex,
		}
	}

	data := clients["grafana"].ClientSecret.ApplyT(func(s string) (string, error) {
		d, err := json.Marshal(map[string]string{"oidc_client_secret": s})
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
		return nil, err
	}

	data = clients["hass"].ClientSecret.ApplyT(func(s string) (string, error) {
		d, err := json.Marshal(map[string]string{"oidc_client_secret": s})
		if err != nil {
			return "", err
		}
		return string(d), nil
	}).(pulumi.StringOutput)

	if _, err := kv.NewSecretV2(ctx, "hass-managed", &kv.SecretV2Args{
		Mount:    kvMount.Path,
		Name:     pulumi.String("prod/services/home-assistant/managed"),
		DataJson: data,
	}); err != nil {
		return nil, err
	}

	return clients, nil
}
