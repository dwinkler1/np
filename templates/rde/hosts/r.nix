# R-related host configurations
#
# This module defines R-related commands available in the dev shell.
# R is configured with project-local package library and Quarto support.
#
# Available commands (when R is enabled):
#   - <name>-r: Launch R console with packages
#
# How it works:
#   - Uses rWrapper which includes all packages from overlays/r.nix
#   - R_LIBS_USER=./.Rlibs enables project-local package installation
#   - --no-save --no-restore ensures clean session startup
#
# Package management:
#   - System packages: Edit overlays/r.nix
#   - Project packages: Install with install.packages() in R
#   - Custom packages: Create r-packages.nix in project root
#
# Dependencies: rWrapper, quarto, air-formatter (configured in flake.nix)
config: pkgs: {
  # r: R console with pre-configured packages
  # Includes tidyverse, data.table, and other common packages
  # Session starts without saving/restoring workspace
  r = {
    enable = config.enabledLanguages.r;
    path = {
      value = "${pkgs.rWrapper}/bin/R";
      args = ["--add-flags" "--no-save --no-restore"];
    };
  };
}
