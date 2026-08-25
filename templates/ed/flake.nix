{
  description = "Project Editor";

  outputs = {
    self,
    nixpkgs,
    nvimConfig,
    ...
  }: let
    systems = ["aarch64-darwin" "x86_64-linux" "aarch64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs systems;

    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [nvimConfig.overlays.dependencies];
      };

    projectModule = pkgs: let
      baseConfig = nvimConfig.wrapperConfigs.default {inherit pkgs;};
      extraRPackages =
        if builtins.pathExists ./r-packages.nix
        then import ./r-packages.nix pkgs.rpkgs
        else [];

      extraPythonPackages =
        if builtins.pathExists ./python-packages.nix
        then import ./python-packages.nix pkgs.python3Packages
        else [];

      extraJuliaPackages =
        if builtins.pathExists ./julia-packages.nix
        then import ./julia-packages.nix
        else [];

      projectName = builtins.baseNameOf (toString self.outPath);
    in {
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

      settings = {
        lang_packages = {
          python = with pkgs.python3Packages;
            [
              requests
            ]
            ++ extraPythonPackages;

          r =
            (with pkgs.rpkgs.rPackages; [
              fixest
            ])
            ++ extraRPackages;

          julia =
            ["StatsBase"]
            ++ extraJuliaPackages;
        };

        colorscheme = "tokyonight"; #"kanagawa";
        background = "dark";
        wrapRc = true;
      };

      binName = "nv";

      env.IS_PROJECT_EDITOR = "1";

      catPkgs = {
        always = [
          pkgs.git
          pkgs.pre-commit
          pkgs.cowsay
        ];

        nix = [
          pkgs.nil
          pkgs.nixfmt
        ];
      };

      specs.extraLua = {
        before = ["INIT_MAIN"];
        data = pkgs.writeText "project-startup.lua" ''
          require("mini.notify").setup()
          vim.notify = MiniNotify.make_notify()
          vim.notify("Welcome to ${projectName}!")
        '';
      };
    };
  in {
    formatter = forAllSystems (system: (mkPkgs system).nixfmt-tree);

    packages = forAllSystems (system: let
      pkgs = mkPkgs system;
    in {
      default = nvimConfig.lib.mkWrapper {
        inherit pkgs;
        modules = [(projectModule pkgs)];
      };
    });

    devShells = forAllSystems (system: let
      pkgs = mkPkgs system;
      evalResult = nvimConfig.lib.eval {
        inherit pkgs;
        modules = [(projectModule pkgs)];
      };
      nv = evalResult.config.wrap {inherit pkgs;};
    in {
      default = pkgs.mkShell {
        packages =
          [
            nv
          ]
          ++ nvimConfig.lib.devShellPackages evalResult.config;
        shellHook =
          nvimConfig.lib.shellHook evalResult.config;
      };
    });
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    rixpkgs.url = "github:dwinkler1/rixpkgs/af2dd3f7b4b172077747c0869d4e30702fb71b0e";

    fran = {
      url = "github:dwinkler1/fran";
      inputs.nixpkgs.follows = "rixpkgs";
    };

    nvimConfig = {
      url = "github:dwinkler1/nvimConfig";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rixpkgs.follows = "rixpkgs";
        fran.follows = "fran";
      };
    };
  };
}
