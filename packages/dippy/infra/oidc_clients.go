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

	if _, err := newOIDCClientKVSecret(ctx, kvMount, "grafana-managed", "grafana", clients["grafana"].ClientSecret); err != nil {
		return nil, err
	}
	if _, err := newOIDCClientKVSecret(ctx, kvMount, "hass-managed", "home-assistant", clients["hass"].ClientSecret); err != nil {
		return nil, err
	}
	if _, err := newOIDCClientKVSecret(ctx, kvMount, "gitlab-managed", "gitlab", clients["gitlab"].ClientSecret); err != nil {
		return nil, err
	}
	if _, err := newOIDCClientKVSecret(ctx, kvMount, "miniflux-managed", "miniflux", clients["miniflux"].ClientSecret); err != nil {
		return nil, err
	}

	return clients, nil
}

func newOIDCClientKVSecret(ctx *pulumi.Context, kvMount *vault.Mount, name string, svcName string, clientSecret pulumi.StringOutput) (*kv.SecretV2, error) {
	data := clientSecret.ApplyT(func(s string) (string, error) {
		d, err := json.Marshal(map[string]string{"oidc_client_secret": s})
		if err != nil {
			return "", err
		}
		return string(d), nil
	}).(pulumi.StringOutput)

	return kv.NewSecretV2(ctx, name, &kv.SecretV2Args{
		Mount:    kvMount.Path,
		Name:     pulumi.Sprintf("prod/services/%s/managed", svcName),
		DataJson: data,
	})
}
