{ config, ... }:
{
  services.vault-agent.instances.main = {
    roleId = "29829ea8-3eb2-b3d6-8aab-d150dbb48e3d";
    secretIdFile = config.age.secrets."vault-secret-id".path;
  };

  age.secrets."vault-secret-id".file = ../../../secrets/leto-approle-secret-id.age;
}
