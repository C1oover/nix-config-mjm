{ inputs, modulesPath, ... }:
{
  disabledModules = [ "${modulesPath}/tasks/filesystems/bcachefs.nix" ];

  imports = [
    "${inputs.nixos-bcachefs-clevis-systemd}/nixos/modules/tasks/filesystems/bcachefs.nix"
  ];
}
