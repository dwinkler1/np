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
              lspsAndRuntimeDeps.rdev = with pkgs; [
                rWrapper
                just
                wget
              ];
            }
          );

          packageDefinitions =
            prev.packageDefinitions
            // {
              nixCats = utils.mergeCatDefs prev.packageDefinitions.nixCats (
                {...}: {
                  settings = {
                    suffix-path = false;
                    suffix-LD = false;
                  };
                  categories = {
                    rdev = true;
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
