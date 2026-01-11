#!/usr/bin/env bash
set -euo pipefail
if [[ -f "devenv.nix" ]]; then
  echo "🚀 Activating devenv environment..."
  if ! command -v @defaultPackageName@-devenv &> /dev/null; then
    echo "❌ Command '@defaultPackageName@-devenv' not found."
    echo "Ensure devenv is properly configured in your environment."
    exit 1
  fi
  exec @defaultPackageName@-devenv shell
else
  echo "❌ No devenv.nix file found in the current directory."
  echo "To create one, run '@defaultPackageName@-initDevenv'"
  exit 1
fi
