{ pkgs, config, ... }:
let
  roleId = "29829ea8-3eb2-b3d6-8aab-d150dbb48e3d";
  secretIdFile = config.age.secrets."approle-secret-id".path;
  vaultAddr = "http://vault.service.consul:8200";

  consulTemplateConfig = {
    once = true;
    vault.address = vaultAddr;
    template = [
      {
        contents = ''{{ with secret "kv/netbox" }}{{ .Data.data.secret_key }}{{ end }}'';
        destination = "/run/vault-secrets/netbox-secret-key";
        user = "netbox";
        perms = "0400";
      }
    ];
  };

  format = pkgs.formats.json { };
  cfgFile = format.generate "secrets-template-config.json" consulTemplateConfig;
in
{
  fileSystems."/run/vault-secrets" = {
    device = "none";
    fsType = "ramfs";
    options = [
      "nodev"
      "nosuid"
      "mode=0751"
    ];
  };

  systemd.services.render-vault-secrets = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    path = with pkgs; [
      vault
      consul-template
      glibc.getent
    ];
    script = ''
      role_id=${roleId}
      secret_id="$(cat ${secretIdFile})"

      VAULT_TOKEN="$(vault write -field=token auth/approle/login role_id=$role_id secret_id=$secret_id)"
      export VAULT_TOKEN

      exec consul-template -config ${cfgFile} -exec true
    '';
    environment = {
      VAULT_ADDR = vaultAddr;
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  age.secrets."approle-secret-id".file = ../../secrets/leto-approle-secret-id.age;
}
