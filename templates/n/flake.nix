{
  description = "New Project";
  inputs = {
    rixpkgs.url = "https://github.com/rstats-on-nix/nixpkgs/archive/2025-08-11.tar.gz";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:dwinkler1/nixCatsConfig";
    nixCats.inputs.nixpkgs.follows = "nixpkgs";
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
  in {
    packages = forSystems (
      system: let
        inherit (nixCats) utils;
        finalPackage = nixCats.packages.${system}.default.override (prev: {
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
              (
                final: prev: let
                  reqPkgs = pyPackages:
                    with pyPackages; [
                      ipython
                      numpy
                      optuna
                      polars
                      requests
                      scikit-learn
                      statsmodels
                      xgboost
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
                  radianWrapper
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
                project = [];
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
                r = {
                  R_LIBS_USER = "./.Rlibs";
                };
                python = {
                  # Prevent uv from managing Python downloads
                  UV_PYTHON_DOWNLOADS = "never";
                  # Force uv to use nixpkgs Python interpreter
                  UV_PYTHON = pkgs.python.interpreter;
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
              ## p => project, n => neovim (global) from nixCats
              p = utils.mergeCatDefs prev.packageDefinitions.n (
                {
                  pkgs,
                  name,
                  ...
                }: {
                  settings = {
                    suffix-path = false;
                    suffix-LD = false;
                    hosts = {
                      m = {
                        enable = true;
                        path = {
                          value = "${pkgs.uv}/bin/uv";
                          args = ["--add-flags" "run marimo edit"];
                        };
                      };
                    };
                  };
                  categories = {
                    julia = true;
                    python = true;
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
  };
}
