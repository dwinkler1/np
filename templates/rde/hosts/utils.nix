# Utility and common host configurations
#
# This module defines general-purpose commands and utilities.
# These commands are available regardless of enabled languages.
#
# Available commands:
#   - <name>: Launch Neovim editor (default command)
#   - <name>-g: Launch Neovide (GUI for Neovim)
#   - <name>-initProject: Initialize project directory structure
#   - <name>-updateDeps: Update all dependencies (R, Python, Julia, flake)
#   - <name>-initDevenv: Initialize devenv project (if enabled)
#   - <name>-devenv: Run devenv commands (if enabled)
#   - <name>-activateDevenv: Activate devenv shell (if enabled)
#
# Note: node, perl, ruby are also available but have minimal configuration
#
# Dependencies: neovide, devenv (if enabled), project scripts
config: pkgs: {
  # g: Neovide - GUI frontend for Neovim
  # Provides smooth scrolling, animations, and GUI features
  # Automatically connects to the configured Neovim instance
  g = {
    enable = true;
    path = {
      value = "${pkgs.neovide}/bin/neovide";
      args = [
        "--add-flags"
        "--neovim-bin ${config.defaultPackageName}"
      ];
    };
  };

  # initProject: Initialize research project structure
  # Creates standardized directory layout for data analysis
  # Sets up: data/, docs/, figures/, tables/, src/
  # Also initializes git repository and .gitignore
  initProject = {
    enable = true;
    path = {
      value = "${pkgs.initProject}/bin/initProject";
    };
  };

  # initDevenv: Initialize devenv project
  # Devenv provides additional development environment features
  # Only available if config.enabledPackages.devenv = true
  initDevenv = {
    enable = config.enabledPackages.devenv;
    path = {
      value = "${pkgs.devenv}/bin/devenv";
      args = ["--add-flags" "init"];
    };
  };

  # activateDevenv: Activate devenv shell
  # Automatically runs when entering dev shell if devenv.nix exists
  # Only available if config.enabledPackages.devenv = true
  activateDevenv = {
    enable = config.enabledPackages.devenv;
    path = {
      value = "${pkgs.activateDevenv}/bin/activateDevenv";
    };
  };

  # devenv: Run devenv commands
  # Access to full devenv CLI for managing development environments
  # Only available if config.enabledPackages.devenv = true
  devenv = {
    enable = config.enabledPackages.devenv;
    path = {
      value = "${pkgs.devenv}/bin/devenv";
    };
  };

  # updateDeps: Update all project dependencies
  # Updates: R packages (rixpkgs), Python (uv), Julia (Pkg), flake inputs
  # Automatically detects which languages are in use
  updateDeps = {
    enable = true;
    path = {
      value = "${pkgs.updateDeps}/bin/updateDeps";
    };
  };

  # Additional language runtimes with minimal configuration
  # These are available but not heavily used by this template
  node.enable = true;  # Node.js runtime (used by some LSPs)
  perl.enable = true;  # Perl runtime
  ruby.enable = true;  # Ruby runtime
}
