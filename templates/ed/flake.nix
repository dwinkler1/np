{
  description = "Project Editor";

  outputs = {
    self,
    nixpkgs,
    nvimConfig,
    ...
  } @ inputs: let
    projectSettings = {pkgs}: {
      cats = {
        clickhouse = false;
        gitPlugins = false;
        julia = false;
        lua = false;
        markdown = false;
        nix = true;
        optional = false;
        python = false;
        r = false;
      };

      settings = let
        # With `replace` packages are replaced otherwise they are merged with base packages
        replace = pkgs.lib.mkForce;
      in {
        lang_packages = {
          python = replace (
            (with pkgs.python3Packages; [
              duckdb
              polars
            ])
            ++ (
              if builtins.pathExists ./python-packages.nix
              # p: with p; [ ... ]
              then import ./python-packages.nix pkgs.python3Packages
              else []
            )
          );

          r = replace (
            (with pkgs.rpkgs.rPackages; [
              fixest
              # pkgs.extraRPackages.musicMetadata
            ])
            ++ (
              if builtins.pathExists ./r-packages.nix
              # p: with p.rPackages; [ ... ]
              then import ./r-packages.nix pkgs.rpkgs
              else []
            )
          );

          julia = replace ([
              "StatsBase"
            ]
            ++ (
              if builtins.pathExists ./julia-packages.nix
              # [ ... ]
              then import ./julia-packages.nix
              else []
            ));
        };
        colorscheme = "kanagawa";
        background = "dark";
        wrapRc = true;
      };
      binName = "vv";

      env = {
        IS_PROJECT_EDITOR = "1";
        R_LIBS_USER = "./.nvimcom";
      };

      extraPackages = with pkgs; [
        cowsay
      ];

      specs.extraLua = let
        name = builtins.baseNameOf (builtins.toString ./.);
      in {
        data = pkgs.vimPlugins.mini-notify;
        before = ["INIT_MAIN"];
        config = ''
          require("mini.notify").setup()
          vim.notify = MiniNotify.make_notify()
          vim.notify("Welcome to ${name}!")
        '';
      };
    };

    systems = nixpkgs.lib.systems.flakeExposed;
    forAllSystems = nixpkgs.lib.genAttrs systems;
    overlays = [inputs.nvimConfig.overlays.dependencies];
  in {
    packages = forAllSystems (system: let
      pkgs = import nixpkgs {inherit system overlays;};
      baseNvim = nvimConfig.packages.${system}.default;

      nvim = (baseNvim.eval (projectSettings {inherit pkgs;})).config.wrapper;
      default = nvim;
    in {
      default = nvim;
    });

    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {inherit system overlays;};
      nv = self.packages.${system}.default;
    in {
      default = pkgs.mkShell {
        packages = [nv pkgs.updateR];
      };
    });
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    rixpkgs.url = "github:dwinkler1/rixpkgs/nixpkgs";
    fran = {
      url = "github:dwinkler1/fran";
      inputs = {
        nixpkgs.follows = "rixpkgs";
      };
    };
    nvimConfig = {
      url = "github:dwinkler1/nvimConfig";
      inputs = {
        rixpkgs.follows = "rixpkgs";
        nixpkgs.follows = "nixpkgs";
        fran.follows = "fran";
      };
    };
  };
}
