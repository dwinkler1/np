{
  description = "Project Editor";

  outputs = {
    self,
    nixpkgs,
    nvimConfig,
    ...
  } @ inputs: let
    # ── Shared language support flags ──────────────────────────────
    # Used by both the neovim wrapper module and the devShell
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

    # ── Language package lists ────────────────────────────────────
    # Shared between wrapper lang_packages and devShell toolchains.
    # Accept pkgs so they work inside forAllSystems for each system.

    rPackages = pkgs:
      (with pkgs.rpkgs.rPackages; [
        fixest
        # pkgs.extraRPackages.musicMetadata
      ])
      ++ (
        if builtins.pathExists ./r-packages.nix
        # p: with p.rPackages; [ ... ]
        then import ./r-packages.nix pkgs.rpkgs
        else []
      );

    pythonPackages = pkgs:
      (with pkgs.python3Packages; [
        duckdb
        polars
      ])
      ++ (
        if builtins.pathExists ./python-packages.nix
        # p: with p; [ ... ]
        then import ./python-packages.nix pkgs.python3Packages
        else []
      );

    juliaPackages =
      ["StatsBase"]
      ++ (
        if builtins.pathExists ./julia-packages.nix
        # [ ... ]
        then import ./julia-packages.nix
        else []
      );

    systems = ["aarch64-darwin" "x86_64-linux" "aarch64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
    overlays = [inputs.nvimConfig.overlays.dependencies];
  in {
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

    packages = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system overlays;
        config = {allowUnfree = true;};
      };
      # Plain attrset — pkgs is captured from the surrounding scope,
      # so the module system does not need lazy _module.args resolution.
      projectSettings = {
        inherit cats;
        settings = let
          # With `replace` packages are replaced otherwise they are merged with base packages
          replace = pkgs.lib.mkForce;
        in {
          lang_packages = {
            python = replace (pythonPackages pkgs);
            r = replace (rPackages pkgs);
            julia = replace juliaPackages;
          };
          colorscheme = "kanagawa";
          background = "dark";
          wrapRc = true;
        };
        binName = "nv";

        env = {
          IS_PROJECT_EDITOR = "1";
        };

        runtimePkgs = with pkgs; [
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
      evalResult = nvimConfig.inputs.wrappers.lib.evalModules {
        modules = [
          nvimConfig.wrapperModules.default
          projectSettings
        ];
      };
    in {
      default = evalResult.config.wrap {inherit pkgs;};
    });

    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system overlays;
        config = {allowUnfree = true;};
      };
      nv = self.packages.${system}.default;
    in {
      default = pkgs.mkShell {
        packages =
          [nv]

          # ── R toolchain (R REPL, quarto, LSP, formatter) ─────
          ++ pkgs.lib.optionals cats.r (let
            r_packages = (pkgs.baseRPackages or []) ++ rPackages pkgs;
          in [
            (pkgs.rWrapper.override {packages = r_packages;})
            pkgs.radianWrapper
            pkgs.air-formatter
            pkgs.yaml-language-server
            pkgs.nvimcom
            pkgs.rnvimserver
          ])

          # ── Python toolchain (interpreter, LSP, formatter) ────
          ++ pkgs.lib.optionals cats.python [
            (pkgs.python3.withPackages (ps: pkgs.basePythonPackages ps ++ pythonPackages pkgs))
            pkgs.nodejs
            pkgs.ruff
            pkgs.basedpyright
            pkgs.uv
          ]

          # ── Julia toolchain ───────────────────────────────────
          ++ pkgs.lib.optionals cats.julia [
            pkgs.julia-bin.withPackages juliaPackages
          ]

          # ── Markdown toolchain (quarto, zk) ───────────────────
          ++ (let
            r_packages = (pkgs.baseRPackages or []) ++ rPackages pkgs;
            quarto =
              if cats.r
              then pkgs.quarto.override {extraRPackages = r_packages;}
              else pkgs.quarto;
          in pkgs.lib.optionals cats.markdown [
            pkgs.python313Packages.pylatexenc
            quarto
            pkgs.zk
          ]);
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
