# Python-related host configurations
#
# This module defines all Python-related commands available in the dev shell.
# Each command is configured with enable conditions and execution paths.
#
# Available commands (when Python is enabled):
#   - <name>-marimo: Launch Marimo notebook (interactive Python notebooks)
#   - <name>-py: Run Python interpreter
#   - <name>-ipy: Launch IPython REPL (enhanced interactive shell)
#   - <name>-initPython: Initialize Python project with uv
#
# How it works:
#   - Commands are enabled based on config.enabledLanguages.python
#   - UV (Python package manager) handles project dependencies
#   - Each command auto-initializes project if pyproject.toml doesn't exist
#
# Dependencies: uv, python, nodejs, basedpyright (configured in flake.nix)
config: pkgs: {
  # Marimo: Interactive notebook environment for Python
  # Auto-initializes UV project and installs marimo on first run
  marimo = let
    marimoInit = ''
      set -euo pipefail
      if [[ ! -f "pyproject.toml" ]]; then
        echo "🐍 Initializing UV project..."
        uv init
        echo "📦 Adding Marimo..."
        uv add marimo
        echo "--------------------------------------------------------------------------"
        echo "✅ Python project initialized!"
        echo "run 'uv add PACKAGE' to add more python packages."
        echo "--------------------------------------------------------------------------"
      else
        echo "--------------------------------------------------------------------------"
        echo "🔄 Syncing existing project..."
        uv sync
        echo "🐍 Launching Marimo..."
        echo "--------------------------------------------------------------------------"
      fi
    '';
  in {
    enable = config.enabledLanguages.python;
    path = {
      value = "${pkgs.uv}/bin/uv";
      args = [
        "--run"
        "${marimoInit}"
        "--add-flags"
        "run marimo edit \"$@\""
      ];
    };
  };

  # py: Standard Python interpreter
  # Direct access to Python REPL for quick experiments
  py = {
    enable = config.enabledLanguages.python;
    path = {
      value = "${pkgs.python.interpreter}";
    };
  };

  # ipy: IPython - Enhanced interactive Python shell
  # Features: syntax highlighting, tab completion, magic commands
  # Auto-initializes UV project and installs IPython on first run
  ipy = let
    ipythonInit = ''
      set -euo pipefail
      if [[ ! -f "pyproject.toml" ]]; then
        echo "🐍 Initializing UV project..."
        uv init
        echo "📦 Adding IPython..."
        uv add ipython
        echo "--------------------------------------------------------------------------"
        echo "✅ Python project initialized!"
        echo "run 'uv add PACKAGE' to add more python packages."
        echo "--------------------------------------------------------------------------"
      else
        echo "--------------------------------------------------------------------------"
        echo "🔄 Syncing existing project..."
        echo "📦 Ensuring IPython is installed..."
        uv add ipython
        uv sync
        echo "🐍 Launching IPython..."
        echo "--------------------------------------------------------------------------"
      fi
    '';
  in {
    enable = config.enabledLanguages.python;
    path = {
      value = "${pkgs.uv}/bin/uv";
      args = [
        "--run"
        "${ipythonInit}"
        "--add-flags"
        "run ipython \"$@\""
      ];
    };
  };

  # initPython: Initialize Python project
  # Creates pyproject.toml and adds IPython and Marimo
  # Use this to set up Python tooling in an existing project
  initPython = {
    enable = config.enabledLanguages.python;
    path.value = "${pkgs.initPython}/bin/initPython";
  };
}
