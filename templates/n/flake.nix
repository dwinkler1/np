{
  description = "New Project";
  inputs = {
    rixpkgs.url = "https://github.com/rstats-on-nix/nixpkgs/archive/2025-08-11.tar.gz";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:dwinkler1/nixCatsConfig";
    nixCats.inputs.nixpkgs.follows = "nixpkgs";
    nixCats.inputs.rixpkgs.follows = "rixpkgs";
    ## All git packages managed per project
    "plugins-r" = {
      url = "github:R-nvim/R.nvim";
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
  outputs = {
    self,
    nixpkgs,
    nixCats,
    ...
  } @ inputs: let
    forSystems = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
    defaultPackageName = "p";
    projectConfig = forSystems (
      system: let
        inherit (nixCats) utils;
        inherit defaultPackageName;
        prevPackage = nixCats.packages.${system}.default;
        finalPackage = prevPackage.override (prev: {
          name = "p";
          dependencyOverlays =
            prev.dependencyOverlays
            ++ [
              (utils.standardPluginOverlay inputs)
              ## Pull in local rix copy
              (final: prev: {
                rpkgs = inputs.rixpkgs.legacyPackages.${prev.system};
              })
              ## Define project level R packages
              (
                final: prev: let
                  reqPkgs = with prev.rpkgs.rPackages; [
                    Hmisc
                    Rcpp
                    arm
                    broom
                    car
                    data_table
                    devtools
                    janitor
                    konfound
                    languageserver
                    quarto
                    reprex
                    styler
                    tidyverse
                    (buildRPackage {
                      name = "nvimcom";
                      src = inputs.plugins-r;
                      sourceRoot = "source/nvimcom";
                      buildInputs = with prev.rpkgs; [
                        R
                        stdenv.cc.cc
                        gnumake
                      ];
                      propagatedBuildInputs = [];
                    })
                  ];
                in {
                  quarto = prev.rpkgs.quarto.override {extraRPackages = reqPkgs;};
                  rWrapper = prev.rpkgs.rWrapper.override {packages = reqPkgs;};
                }
              )

              ## Define project level Python Packages
              ## Only use if uv should not be used
              (
                final: prev: let
                  reqPkgs = pyPackages:
                    with pyPackages; [
                      numpy
                      polars
                      requests
                    ];
                in {
                  python = prev.python3.withPackages reqPkgs;
                }
              )
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
                project = with pkgs; [
                ];
                julia = with pkgs; [
                  julia-bin
                ];
                python = with pkgs; [
                  python
                  nodejs
                  pyright
                  uv
                ];
                r = with pkgs; [
                  rWrapper
                  quarto
                  air-formatter
                ];
              };

              startupPlugins = {
                project = with pkgs.vimPlugins; [
                ];
                gitPlugins = with pkgs.neovimPlugins; [
                  {
                    plugin = r;
                    config.lua = "vim.notify('Using project local R plugin')";
                  }
                ];
              };

              optionalPlugins = {
                project = with pkgs.vimPlugins; [
                ];
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
                project = [
                  "vim.notify('Project loaded: ${name}')"
                ];
              };
              sharedLibraries = {
                project = {
                };
              };

              environmentVariables = {
                project = {
                };
                julia = {
                  JULIA_NUM_THREADS = "auto";
                };
                python = {
                  # Prevent uv from managing Python downloads
                  UV_PYTHON_DOWNLOADS = "never";
                  # Force uv to use nixpkgs Python interpreter
                  UV_PYTHON = pkgs.python.interpreter;
                };
                r = {
                  R_LIBS_USER = "./.Rlibs";
                };
              };

              extraWrapperArgs = {
                python = [
                  "--unset PYTHONPATH"
                ];
              };
            }
          );

          packageDefinitions =
            prev.packageDefinitions
            // {
              p = utils.mergeCatDefs prev.packageDefinitions.n (
                {
                  pkgs,
                  name,
                  ...
                }: {
                  settings = {
                    suffix-path = false;
                    suffix-LD = false;
                    # your alias may not conflict with your other packages.
                    aliases = ["pvim"];
                    hosts = {
                      g = {
                        enable = true;
                        path = {
                          value = "${pkgs.neovide}/bin/neovide";
                          args = [
                            "--add-flags"
                            "--neovim-bin ${name}"
                          ];
                        };
                      };
                      m = let
                        preHookInit = ''
                          # Check if pyproject.toml exists
                          if [ ! -f "pyproject.toml" ]; then
                              echo "pyproject.toml not found. Initializing new UV project..."

                              # Initialize UV project
                              uv init

                              # Check if uv init was successful
                              if [ $? -eq 0 ]; then
                                  echo "UV project initialized successfully."

                                  # Add marimo dependency
                                  echo "Adding marimo dependency..."
                                  uv add marimo

                                  if [ $? -eq 0 ]; then
                                      echo "Marimo added successfully!"
                                  else
                                      echo "Error: Failed to add marimo dependency."
                                      exit 1
                                  fi
                              else
                                  echo "Error: Failed to initialize UV project."
                                  exit 1
                              fi
                          else
                              echo "pyproject.toml already exists. Syncing...."
                              uv sync
                          fi
                        '';
                      in {
                        enable = true;
                        path = {
                          value = "${pkgs.uv}/bin/uv";
                          args = [
                            "--run"
                            "${preHookInit}"
                            "--add-flags"
                            "run marimo edit"
                          ];
                        };
                      };
                      jl = {
                        enable = false;
                        path = {
                          value = "${pkgs.julia-bin}/bin/julia";
                          args = ["--add-flags" "--project=@."];
                        };
                      };
                      r = {
                        enable = true;
                        path = {
                          value = "${pkgs.rWrapper}/bin/R";
                          args = ["--add-flags" "--no-save --no-restore"];
                        };
                      };
                      node.enable = true;
                      perl.enable = true;
                      ruby.enable = true;
                    };
                  };
                  categories = {
                    julia = false;
                    python = false;
                    r = true;
                    project = true;
                    gitPlugins = true;
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
      default = pkgs.mkShell {
        name = defaultPackageName;
        packages = [projectConfig.${system}.default];
        inputsFrom = [];
        shellHook = ''
        '';
      };
    });
  };
}
