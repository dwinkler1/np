# Merges all host configurations from separate modules
#
# This file combines host definitions from language-specific modules.
# It serves as the single entry point for all command definitions.
#
# Structure:
#   - python.nix: Python commands (marimo, ipy, py, initPython)
#   - julia.nix: Julia commands (jl, pluto, initJl)
#   - r.nix: R commands (r console)
#   - utils.nix: Utility commands (initProject, updateDeps, etc.)
#
# Usage:
#   This file is imported in flake.nix:
#   hosts = import ./hosts config pkgs;
#
# The merged result provides all commands in a single attribute set.
# Commands are enabled/disabled based on config.enabledLanguages settings.
config: pkgs: let
  # Import individual host modules
  pythonHosts = import ./python.nix config pkgs;
  juliaHosts = import ./julia.nix config pkgs;
  rHosts = import ./r.nix config pkgs;
  utilsHosts = import ./utils.nix config pkgs;
in
  # Merge all hosts into single attribute set
  # Later definitions override earlier ones in case of conflicts
  pythonHosts // juliaHosts // rHosts // utilsHosts
