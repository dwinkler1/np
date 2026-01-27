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
    # Each overlay adds specific packages or configurations
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

    # Main package configuration
    # This configures the Neovim environment with language support
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
              # Language servers and runtime dependencies
              lspsAndRuntimeDeps = {
                project = with pkgs; [];
                julia = with pkgs; [julia-bin];
                python = with pkgs; [python nodejs basedpyright uv];
                r = with pkgs; [rWrapper quarto air-formatter];
              };

              # Plugins that load automatically
              startupPlugins = {
                project = with pkgs.vimPlugins; [pkgs.extraTheme];
                gitPlugins = with pkgs.neovimPlugins; [
                  {
                    plugin = r;
                    config.lua = "vim.notify('Using project local R plugin')";
                  }
                ];
              };

              # Plugins that load on-demand
              optionalPlugins = {
                project = with pkgs.vimPlugins; [];
                gitPlugins = with pkgs.neovimPlugins; [
                  cmp-r
                  cmp-pandoc-references
                ];
              };

              # Lua code to run before main config
              optionalLuaPreInit = {
                project = [
                  (builtins.readFile ./lib/mini-notify-config.lua)
                ];
              };

              # Lua code to run after main config
              optionalLuaAdditions = {
                project = ["vim.notify('Project loaded: ${name}')"];
              };

              sharedLibraries = {
                project = {};
              };

              # Environment variables for each language
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
              # Main package definition
              # This creates the command with configured languages and tools
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
                    # Import all host commands from hosts/ directory
                    hosts = import ./hosts config pkgs;
                  };
                  # Enable/disable features based on config
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
    # Development shell configuration
    devShells = forSystems (system: let
      pkgs = import nixpkgs {inherit system;};
      # Language-specific packages that should be available in shell
      languagePackages = with pkgs;
        []
        ++ (if config.enabledLanguages.r then [quarto] else [])
        ++ (if config.enabledLanguages.python then [uv] else [])
        ++ (if config.enabledLanguages.julia then [] else []);
    in {
      default = pkgs.mkShell {
        name = config.defaultPackageName;
        packages = [projectConfig.${system}.default] ++ languagePackages;
        inputsFrom = [];
        # Welcome message when entering the shell
        shellHook = import ./lib/shell-hook.nix config pkgs;
      };
    });
  };
  inputs = {
    rixpkgs.url = "github:rstats-on-nix/nixpkgs/2026-01-19";
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
