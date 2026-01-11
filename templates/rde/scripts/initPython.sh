#!/usr/bin/env bash
set -euo pipefail
if [[ ! -f "pyproject.toml" ]]; then
  echo "🐍 Initializing UV project..."
  uv init
  echo "📦 Adding IPython and Marimo..."
  uv add ipython
  uv add marimo
  echo "--------------------------------------------------------------------------"
  echo "✅ Python project initialized!"
  echo "run 'uv add PACKAGE' to add more python packages."
  echo "--------------------------------------------------------------------------"
else
  echo "--------------------------------------------------------------------------"
  echo "🔄 Existing Python project detected."
  echo "📦 Ensuring IPython and Marimo are installed..."
  uv add ipython
  uv add marimo
  echo "Run '@defaultPackageName@-updateDeps' to update dependencies."
  echo "--------------------------------------------------------------------------"
fi
