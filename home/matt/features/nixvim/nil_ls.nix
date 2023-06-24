{pkgs, ...}: {
  programs.nixvim.plugins.lsp.servers.nil_ls = {
    enable = true;
    settings.formatting.command = ["${pkgs.alejandra}/bin/alejandra"];
  };
}
