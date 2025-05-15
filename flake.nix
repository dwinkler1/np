{
  description = "Project Template";
  inputs = {
    nixpkgs = {
      url = "https://github.com/rstats-on-nix/nixpkgs/archive/2025-05-05.tar.gz";
    };
    nCats.url = "github:dwinkler1/nixCatsConfig";
    nCats.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    {
      self,
      nixpkgs,
      nCats,
      ...
    }@inputs:
    let
      forSystems = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
    in
    {
      packages = forSystems (
        system:
        let

          inherit (nCats) utils;
          finalPackage = nCats.packages.${system}.default.override (prev: {
            categoryDefinitions = utils.mergeCatDefs prev.categoryDefinitions (
              {
                pkgs,
                settings,
                categories,
                name,
                extra,
                mkPlugin,
                ...
              }@packageDef:
              let
                rpkgs = import ./rpkgs.nix pkgs;
              in
              {
                lspsAndRuntimeDeps.rdev = with pkgs; [
                  (rWrapper.override {
                    packages = rpkgs;
                  })
                ];
              }
            );

            packageDefinitions = prev.packageDefinitions // {
              nixCats = utils.mergeCatDefs prev.packageDefinitions.nixCats (
                { ... }:
                {
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
        # and
        utils.mkAllWithDefault finalPackage

      );
    };
}
