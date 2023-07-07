{pkgs, ...}: {
  imports = [
    ./catppuccin.nix
    ./cmp.nix
    ./comment-nvim.nix
    ./ide.nix
    ./lsp.nix
    ./lua_ls.nix
    ./lualine.nix
    ./neotree.nix
    ./nil_ls.nix
    ./null_ls.nix
    ./telescope.nix
    ./treesitter.nix
  ];

  programs.nixvim = {
    enable = true;
    wrapRc = true;
    viAlias = true;
    vimAlias = true;
    globals = {
      mapleader = " ";
    };
    options = {
      breakindent = true;
      clipboard = "unnamedplus";
      cmdheight = 0;
      completeopt = ["menu" "menuone" "noselect"];
      copyindent = true;
      cursorline = true;
      expandtab = true;
      fileencoding = "utf-8";
      ignorecase = true;
      infercase = true;
      laststatus = 3;
      linebreak = true;
      mouse = "a";
      number = true;
      preserveindent = true;
      pumheight = 10;
      scrolloff = 8;
      shiftwidth = 2;
      showmode = false;
      showtabline = 2;
      sidescrolloff = 8;
      signcolumn = "yes";
      splitbelow = true;
      splitright = true;
      tabstop = 2;
      timeoutlen = 500;
      undofile = true;
      updatetime = 300;
      virtualedit = "block";
      wrap = false;
      writebackup = false;
    };
    maps.normal = {
      " " = {
        action = "<Nop>";
        silent = true;
      };
      "<leader>w" = {
        action = "<cmd>w<cr>";
        desc = "Save";
      };
      "<leader>q" = {
        action = "<cmd>confirm q<cr>";
        desc = "Quit";
      };
      "|" = {
        action = "<cmd>vsplit<cr>";
        desc = "Vertical Split";
      };
      "\\" = {
        action = "<cmd>split<cr>";
        desc = "Horizontal Split";
      };
      "<leader>c" = {
        action = "<cmd>BufferClose<cr>";
        desc = "Close buffer";
      };
      "<leader>bc" = {
        action = "<cmd>BufferCloseAllButCurrentOrPinned<cr>";
        desc = "Close all buffers except current";
      };
      "]b" = {
        action = "<cmd>BufferNext<cr>";
        desc = "Next buffer";
      };
      "[b" = {
        action = "<cmd>BufferPrevious<cr>";
        desc = "Previous buffer";
      };
    };
    extraPlugins = with pkgs.vimPlugins; [
      nvim-web-devicons
      guess-indent-nvim
      flit-nvim
      vim-smoothie
    ];
    colorschemes.catppuccin = {
      integrations.barbar = true;
      integrations.gitsigns = true;
      integrations.which_key = true;
    };
    plugins.barbar.enable = true;
    plugins.leap.enable = true;
    plugins.gitsigns.enable = true;
    plugins.nix.enable = true;
    plugins.which-key.enable = true;

    extraConfigLua = ''
      require('guess-indent').setup {}
      require('flit').setup {}
    '';
  };
}
