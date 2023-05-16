{ pkgs, ... }: {
  mkConfig =
    { roleId
    , secretIdFile
    , templates
    , ...
    }:
    let
      roleIdFile = pkgs.writeText "role-id" roleId;
    in
    {
      vault.address = "http://vault.service.consul:8200";
      auto_auth.method = [
        {
          type = "approle";
          config = {
            remove_secret_id_file_after_reading = false;
            role_id_file_path = "${roleIdFile}";
            secret_id_file_path = secretIdFile;
          };
        }
      ];
      template = templates;
    };
}
