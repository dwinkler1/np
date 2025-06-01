{
  description = "Project Template";
  inputs = {
    rixpkgs.url = "https://github.com/rstats-on-nix/nixpkgs/archive/2025-05-19.tar.gz";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nCats.url = "github:dwinkler1/nixCatsConfig";
    nCats.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {
    self,
    nixpkgs,
    nCats,
    ...
  } @ inputs: let
    forSystems = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
  in {
    packages = forSystems (
      system: let
        inherit (nCats) utils;
        finalPackage = nCats.packages.${system}.default.override (prev: {
          dependencyOverlays =
            prev.dependencyOverlays
            ++ [
              (utils.standardPluginOverlay inputs)
              (final: prev: {
                rpkgs = inputs.rixpkgs.legacyPackages.${system};
              })
              (import (builtins.path {
                path = ./rpkgs.nix;
                name = "my-rpackages";
              }))
              (import (builtins.path {
                path = ./pypkgs.nix;
                name = "my-pypackages";
              }))
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
                meta = with pkgs; [
                  just
                  wget
                  gh
                ];
                rdev = with pkgs; [
                  rWrapper
                ];
                pydev = with pkgs; [
                  py
                  uv
                  pyright
                  nodejs
                ];
                jldev = with pkgs; [
                  julia-bin
                ];
              };

              environmentVariables = {
                rdev = {
                  R_LIBS_USER = "./.Rlibs";
                };
                pydev = {
                  # Prevent uv from managing Python downloads
                  UV_PYTHON_DOWNLOADS = "never";
                  # Force uv to use nixpkgs Python interpreter
                  UV_PYTHON = pkgs.py.interpreter;
                };
              };
              extraWrapperArgs = {
                pydev = [
                  "--unset PYTHONPATH"
                ];
              };
              bashBeforeWrapper = {
                pydev = [
                  "uv sync"
                ];
              };
            }
          );

          packageDefinitions =
            prev.packageDefinitions
            // {
              nixCats = utils.mergeCatDefs prev.packageDefinitions.nixCats (
                {pkgs, ...}: {
                  settings = {
                    suffix-path = false;
                    suffix-LD = false;
                    hosts = {
                      python3.enable = true;
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
                    meta = true;
                    rdev = true;
                    pydev = true;
                    jldev = true;
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
