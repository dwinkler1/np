{
  description = "New Project";

  outputs = {
    self,
    nixpkgs,
    nixCats,
    ...
  } @ inputs: let
    #######################
    ### PROJECT CONFIG ####
    #######################
    ## Set options below:
    config = rec {
      ## Set project name
      defaultPackageName = "p";
      ## Enable languages
      enabledLanguages = {
        julia = false;
        python = false;
        r = true;
      };
      ## Enable packages
      enabledPackages = {
        ## Plugins loaded via flake input
        ### Always enable when R is enabled
        ### You can use your own R installation and just enable the plugin
        gitPlugins = enabledLanguages.r;
        ## Create additional dev shells in the project
        devenv = false;
      };
      theme = rec {
        ## set colortheme and background here
        ### "cyberdream", "onedark", and "tokyonight" are pre-installed
        colorscheme = "kanagawa";
        background = "dark";
        ## Add other colortheme packages and config here
        ## The default is a best guess
        extraColorschemePackage = rec {
          name = colorscheme;
          extraLua = ''
            vim.notify("Loading ${colorscheme} with extra config...")
            require('${name}').setup({
              commentStyle = {italic = false},
              keywordStyle = {italic = false},
              theme = 'dragon'
            })
          '';
          plugin = name + "-nvim";
        };
      };
    };

    ###################################
    ## ⬆️ BASIC CONFIG ABOVE HERE ⬆️ ##
    ###################################

    # Import overlays from separate files
    rOverlay = import ./overlays/r.nix;
    pythonOverlay = import ./overlays/python.nix;
    rixOverlay = import ./overlays/rix.nix inputs;
    extraPkgOverlay = import ./overlays/theme.nix config;
    projectScriptsOverlay = import ./overlays/project-scripts.nix config;
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    forSystems = nixpkgs.lib.genAttrs supportedSystems;

    projectConfig = forSystems (
      system: let
        inherit (nixCats) utils;
        inherit (config) defaultPackageName;
        prevPackage = nixCats.packages.${system}.default;
        finalPackage = prevPackage.override (prev: {
          name = config.defaultPackageName;
          dependencyOverlays =
            prev.dependencyOverlays
            ++ [
              (utils.standardPluginOverlay inputs)
              extraPkgOverlay
              rixOverlay
              inputs.fran.overlays.default
              rOverlay
              pythonOverlay
              projectScriptsOverlay
            ];

          categoryDefinitions = utils.mergeCatDefs prev.categoryDefinitions (
            {
              pkgs,
              settings,
              categories,
              name,
              extra,
              mkPlugin,
              ...
            } @ packageDef: {
              lspsAndRuntimeDeps = {
                project = with pkgs; [];
                julia = with pkgs; [julia-bin];
                python = with pkgs; [python nodejs basedpyright uv];
                r = with pkgs; [rWrapper quarto air-formatter];
              };

              startupPlugins = {
                project = with pkgs.vimPlugins; [pkgs.extraTheme];
                gitPlugins = with pkgs.neovimPlugins; [
                  {
                    plugin = r;
                    config.lua = "vim.notify('Using project local R plugin')";
                  }
                ];
              };

              optionalPlugins = {
                project = with pkgs.vimPlugins; [];
                gitPlugins = with pkgs.neovimPlugins; [
                  cmp-r
                  cmp-pandoc-references
                ];
              };

              optionalLuaPreInit = {
                project = [
                  ''
                    local predicate = function(notif)
                      if not (notif.data.source == "lsp_progress" and notif.data.client_name == "lua_ls") then
                        return true
                      end
                      -- Filter out some LSP progress notifications from 'lua_ls'
                      return notif.msg:find("Diagnosing") == nil and notif.msg:find("semantic tokens") == nil
                    end
                    local custom_sort = function(notif_arr)
                      return MiniNotify.default_sort(vim.tbl_filter(predicate, notif_arr))
                    end
                    require("mini.notify").setup({ content = { sort = custom_sort } })
                    vim.notify = MiniNotify.make_notify()
                  ''
                ];
              };

              optionalLuaAdditions = {
                project = ["vim.notify('Project loaded: ${name}')"];
              };

              sharedLibraries = {
                project = {};
              };

              environmentVariables = {
                project = {};
                julia = {JULIA_NUM_THREADS = "auto";};
                python = {
                  UV_PYTHON_DOWNLOADS = "never";
                  UV_PYTHON = pkgs.python.interpreter;
                };
                r = {R_LIBS_USER = "./.Rlibs";};
              };

              extraWrapperArgs = {
                python = ["--unset PYTHONPATH"];
              };
            }
          );

          packageDefinitions =
            prev.packageDefinitions
            // {
              "${config.defaultPackageName}" = utils.mergeCatDefs prev.packageDefinitions.n (
                {
                  pkgs,
                  name,
                  ...
                }: {
                  settings = {
                    suffix-path = false;
                    suffix-LD = false;
                    aliases = ["pvim"];
                    hosts = import ./hosts config pkgs;
                  };
                  categories = {
                    julia = config.enabledLanguages.julia;
                    python = config.enabledLanguages.python;
                    r = config.enabledLanguages.r;
                    project = true;
                    gitPlugins = config.enabledPackages.gitPlugins;
                    background = config.theme.background;
                    colorscheme = config.theme.colorscheme;
                  };
                }
              );
            };
        });
      in
        utils.mkAllWithDefault finalPackage
    );
  in {
    packages = projectConfig;
    devShells = forSystems (system: let
      pkgs = import nixpkgs {inherit system;};
    in {
      default = let
        shellCmds = pkgs.lib.concatLines (pkgs.lib.filter (cmd: cmd != "") [
          (pkgs.lib.optionalString config.enabledLanguages.r "  - ${config.defaultPackageName}-r: Launch R console")
          (pkgs.lib.optionalString config.enabledLanguages.julia "  - ${config.defaultPackageName}-jl: Launch Julia REPL")
          (pkgs.lib.optionalString config.enabledLanguages.julia "  - ${config.defaultPackageName}-pluto: Launch Pluto.jl notebook")
          (pkgs.lib.optionalString config.enabledLanguages.julia "  - ${config.defaultPackageName}-initJl: Init existing Julia project")
          (pkgs.lib.optionalString config.enabledLanguages.python "  - ${config.defaultPackageName}-marimo: Launch Marimo notebook")
          (pkgs.lib.optionalString config.enabledLanguages.python "  - ${config.defaultPackageName}-py: Run python")
          (pkgs.lib.optionalString config.enabledLanguages.python "  - ${config.defaultPackageName}-ipy: Launch IPython REPL")
          (pkgs.lib.optionalString config.enabledLanguages.python "  - ${config.defaultPackageName}-initPython: Init python project")
          (pkgs.lib.optionalString config.enabledPackages.devenv "  - ${config.defaultPackageName}-initDevenv: Init devenv project")
          (pkgs.lib.optionalString config.enabledPackages.devenv "  - ${config.defaultPackageName}-devenv: Run devenv")
          " "
          "To adjust options run: ${config.defaultPackageName} flake.nix"
        ]);
      in
        pkgs.mkShell {
          name = config.defaultPackageName;
          packages = [projectConfig.${system}.default];
          inputsFrom = [];
          shellHook = ''
            echo ""
            echo "=========================================================================="
            echo "🎯  ${config.defaultPackageName} Development Environment"
            echo "---"
            echo "📝  Run '${config.defaultPackageName}-initProject' to set up project structure"
            echo "🔄  Run '${config.defaultPackageName}-updateDeps' to update all dependencies"
            echo "---"
            echo "🚀  Available commands:"
            echo "  - ${config.defaultPackageName}: Launch Neovim"
            echo "  - ${config.defaultPackageName}-g: Launch Neovide"
            echo "${shellCmds}"
            echo "=========================================================================="
            echo ""
            ${pkgs.lib.optionalString config.enabledPackages.devenv "${config.defaultPackageName}-activateDevenv"}
            echo ""
          '';
        };
    });
  };
  inputs = {
    rixpkgs.url = "github:rstats-on-nix/nixpkgs/2025-12-15";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixCats = {
      url = "github:dwinkler1/nixCatsConfig";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rixpkgs.follows = "rixpkgs";
        fran.follows = "fran";
        plugins-cmp-pandoc-references.follows = "plugins-cmp-pandoc-references";
        plugins-cmp-r.follows = "plugins-cmp-r";
        plugins-r.follows = "plugins-r";
      };
    };
    ## Extra R packages
    fran = {
      url = "github:dwinkler1/fran";
      inputs = {
        nixpkgs.follows = "rixpkgs";
        nvimcom.follows = "plugins-r";
      };
    };
    ## Git Plugins
    "plugins-r" = {
      url = "github:R-nvim/R.nvim/v0.99.1";
      flake = false;
    };
    "plugins-cmp-r" = {
      url = "github:R-nvim/cmp-r";
      flake = false;
    };
    "plugins-cmp-pandoc-references" = {
      url = "github:jmbuhr/cmp-pandoc-references";
      flake = false;
    };
  };
  nixConfig = {
    extra-substituters = [
      "https://rstats-on-nix.cachix.org"
      "https://rde.cachix.org"
    ];
    extra-trusted-public-keys = [
      "rstats-on-nix.cachix.org-1:vdiiVgocg6WeJrODIqdprZRUrhi1JzhBnXv7aWI6+F0="
      "rde.cachix.org-1:yRxQYM+69N/dVER6HNWRjsjytZnJVXLS/+t/LI9d1D4="
    ];
  };
}
