# R packages overlay
# 
# This overlay configures the R environment with essential packages for data analysis.
# It combines packages from rstats-on-nix (rpkgs) with custom packages.
#
# Usage:
#   - Edit the package list below to add/remove R packages
#   - Create r-packages.nix in your project root to add custom packages
#   - Custom file format: rpkgs: with rpkgs.rPackages; [ package1 package2 ]
#
# The overlay exports:
#   - quarto: Quarto with R packages
#   - rWrapper: R executable with all packages available
final: prev: let
  # Core R packages for data analysis and development
  reqPkgs = with final.rpkgs.rPackages;
    [
      broom         # Tidy model outputs
      data_table    # Fast data manipulation
      janitor       # Data cleaning helpers
      languageserver # LSP for IDE support
      reprex        # Reproducible examples
      styler        # Code formatting
      tidyverse     # Data science ecosystem
    ]
    # Additional packages from fran overlay
    ++ (with final.extraRPackages; [
      httpgd        # HTTP graphics device for interactive plots
    ])
    # Import custom R packages from project root if file exists
    # Users can create r-packages.nix in their project to add more packages
    # Example r-packages.nix: rpkgs: with rpkgs.rPackages; [ ggplot2 dplyr ]
    ++ (prev.lib.optional (builtins.pathExists ./r-packages.nix) (import ./r-packages.nix final.rpkgs));
in {
  # Quarto with R support and all required packages
  quarto = final.rpkgs.quarto.override {extraRPackages = reqPkgs;};
  # R wrapper with all packages pre-loaded
  rWrapper = final.rpkgs.rWrapper.override {packages = reqPkgs;};
}
