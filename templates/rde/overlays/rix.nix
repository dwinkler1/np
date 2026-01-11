# Rix overlay for R packages from rstats-on-nix
inputs: final: prev: {
  rpkgs = inputs.rixpkgs.legacyPackages.${prev.stdenv.hostPlatform.system};
}
