# Shell hook configuration
#
# This module generates the welcome message displayed when entering the dev shell.
# It provides information about available commands and how to get started.
#
# The message includes:
#   - Project name and welcome banner
#   - Quick start instructions (initProject, updateDeps)
#   - List of all available commands based on enabled languages
#   - Instructions for editing configuration
#
# Commands are conditionally shown based on config.enabledLanguages settings.
# This ensures users only see commands relevant to their configuration.
#
# Usage:
#   Imported in flake.nix as:
#   shellHook = import ./lib/shell-hook.nix config pkgs;
#
# Generates the help message displayed when entering the dev shell
config: pkgs: let
  inherit (config) defaultPackageName enabledLanguages enabledPackages;
  
  # Build dynamic list of available commands based on enabled languages
  # Filters out empty strings for disabled languages
  shellCmds = pkgs.lib.concatLines (pkgs.lib.filter (cmd: cmd != "") [
    (pkgs.lib.optionalString enabledLanguages.r "  - ${defaultPackageName}-r: Launch R console")
    (pkgs.lib.optionalString enabledLanguages.julia "  - ${defaultPackageName}-jl: Launch Julia REPL")
    (pkgs.lib.optionalString enabledLanguages.julia "  - ${defaultPackageName}-pluto: Launch Pluto.jl notebook")
    (pkgs.lib.optionalString enabledLanguages.julia "  - ${defaultPackageName}-initJl: Init existing Julia project")
    (pkgs.lib.optionalString enabledLanguages.python "  - ${defaultPackageName}-marimo: Launch Marimo notebook")
    (pkgs.lib.optionalString enabledLanguages.python "  - ${defaultPackageName}-py: Run python")
    (pkgs.lib.optionalString enabledLanguages.python "  - ${defaultPackageName}-ipy: Launch IPython REPL")
    (pkgs.lib.optionalString enabledLanguages.python "  - ${defaultPackageName}-initPython: Init python project")
    (pkgs.lib.optionalString enabledPackages.devenv "  - ${defaultPackageName}-initDevenv: Init devenv project")
    (pkgs.lib.optionalString enabledPackages.devenv "  - ${defaultPackageName}-devenv: Run devenv")
    " "
    "To adjust options run: ${defaultPackageName} flake.nix"
  ]);
in ''
  echo ""
  echo "=========================================================================="
  echo "🎯  ${defaultPackageName} Development Environment"
  echo "---"
  echo "📝  Run '${defaultPackageName}-initProject' to set up project structure"
  echo "🔄  Run '${defaultPackageName}-updateDeps' to update all dependencies"
  echo "---"
  echo "🚀  Available commands:"
  echo "  - ${defaultPackageName}: Launch Neovim"
  echo "  - ${defaultPackageName}-g: Launch Neovide"
  echo "${shellCmds}"
  echo "=========================================================================="
  echo ""
  # Auto-activate devenv shell if devenv.nix exists (can be disabled in config)
  ${pkgs.lib.optionalString enabledPackages.devenv "${defaultPackageName}-activateDevenv"}
  echo ""
''
