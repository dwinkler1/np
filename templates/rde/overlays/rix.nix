# Rix overlay for R packages from rstats-on-nix
#
# This overlay provides access to R packages from the rstats-on-nix project.
# rstats-on-nix maintains snapshots of CRAN packages built with Nix.
#
# Purpose:
#   - Provides reproducible R package versions
#   - Ensures binary cache availability for faster builds
#   - Maintained by the rstats-on-nix community
#
# The rpkgs attribute gives access to:
#   - rpkgs.rPackages: All CRAN packages
#   - rpkgs.quarto: Quarto publishing system
#   - rpkgs.rWrapper: R with package management
#
# Update the R snapshot date in flake.nix inputs section:
#   rixpkgs.url = "github:rstats-on-nix/nixpkgs/YYYY-MM-DD"
inputs: final: prev: {
  # R packages from rstats-on-nix for the current system
  rpkgs = inputs.rixpkgs.legacyPackages.${prev.stdenv.hostPlatform.system};
}
