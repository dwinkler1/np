# Python-related host configurations
config: pkgs: {
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

  py = {
    enable = config.enabledLanguages.python;
    path = {
      value = "${pkgs.python.interpreter}";
    };
  };

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

  initPython = {
    enable = config.enabledLanguages.python;
    path.value = "${pkgs.initPython}/bin/initPython";
  };
}
