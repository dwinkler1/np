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
        r = true;
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
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

    packages = forAllSystems (system: let
      pkgs = import nixpkgs {inherit system overlays;};
      evalResult = nvimConfig.inputs.wrappers.lib.evalModules {
        modules = [
          nvimConfig.wrapperModules.default
          projectSettings
        ];
      };
    in {
      default = evalResult.config.wrap { inherit pkgs; };
    });

    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {inherit system overlays;};
      nv = self.packages.${system}.default;
    in {
      default = pkgs.mkShell {
        packages = [nv];
      };
    });
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rixpkgs.url = "github:dwinkler1/rixpkgs/af2dd3f7b4b172077747c0869d4e30702fb71b0e";
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
