{pkgs, ...}: {
  programs.nixvim = {
    extraConfigLuaPre = ''
      local mix_cmd
      if vim.fs.basename(vim.loop.cwd()) == "slab" then
        mix_cmd = "docker compose exec slab_1 mix"
      else
        mix_cmd = "mix"
      end

      local run_last_test = function()
        os.execute(
          "${pkgs.kitty}/bin/kitty @ --to="
          .. os.getenv("KITTY_LISTEN_ON")
          .. " launch --type=overlay --cwd=current ${pkgs.zsh}/bin/zsh -l -i -c '"
          .. mix_cmd
          .. " "
          .. vim.g.my_last_test
          .. "; read'"
        )
      end
    '';
    maps.normal = {
      "<leader>TT" = {
        action = "run_last_test";
        lua = true;
        desc = "Re-run last test";
      };
      "<leader>TA" = {
        action = ''
          function()
            vim.g.my_last_test = "test.all"
            run_last_test()
          end
        '';
        lua = true;
        desc = "Test entire project";
      };
      "<leader>TF" = {
        action = ''
          function()
            vim.g.my_last_test = "test " .. vim.fn.expand("%")
            run_last_test()
          end
        '';
        lua = true;
        desc = "Test current file";
      };
      "<leader>TL" = {
        action = ''
          function()
            vim.g.my_last_test = "test " .. vim.fn.expand("%") .. ":" .. vim.api.nvim_win_get_cursor(0)[1]
            run_last_test()
          end
        '';
        lua = true;
        desc = "Test current file";
      };
    };
  };
}
