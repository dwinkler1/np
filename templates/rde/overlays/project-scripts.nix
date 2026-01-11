# Project scripts overlay
#
# This overlay wraps shell scripts from the scripts/ directory as Nix packages.
# Scripts are made available as executable commands with the project name prefix.
#
# How it works:
#   1. Reads shell scripts from scripts/ directory
#   2. Substitutes @defaultPackageName@ with actual package name
#   3. Creates executable packages via writeShellScriptBin
#   4. Scripts become available as: <packageName>-<scriptName>
#
# Available scripts:
#   - initPython: Initialize Python project with uv
#   - initProject: Set up project directory structure
#   - updateDeps: Update all dependencies (R, Python, Julia, flake)
#   - activateDevenv: Activate devenv shell if available
#
# Usage: Scripts are automatically available in the dev shell
config: final: prev: let
  # Helper function to substitute config placeholders in scripts
  # Replaces @defaultPackageName@ with the actual package name from config
  substituteScript = scriptPath:
    prev.lib.replaceStrings
      ["@defaultPackageName@"]
      [config.defaultPackageName]
      (builtins.readFile scriptPath);
in {
  # Python project initialization (creates pyproject.toml, adds packages)
  initPython = prev.writeShellScriptBin "initPython" (substituteScript ../scripts/initPython.sh);
  
  # Project structure setup (creates directories, git repo, .gitignore)
  initProject = prev.writeShellScriptBin "initProject" (substituteScript ../scripts/initProject.sh);
  
  # Update all dependencies (R packages, Python packages, flake inputs)
  updateDeps = prev.writeShellScriptBin "updateDeps" (substituteScript ../scripts/updateDeps.sh);
  
  # Activate devenv environment if devenv.nix exists
  activateDevenv = prev.writeShellScriptBin "activateDevenv" (substituteScript ../scripts/activateDevenv.sh);
}
