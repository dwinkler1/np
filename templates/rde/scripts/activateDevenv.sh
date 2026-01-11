#!/usr/bin/env bash
set -euo pipefail
if [[ -f "devenv.nix" ]]; then
  echo "🚀 Activating devenv environment..."
  exec @defaultPackageName@-devenv shell
else
  echo "❌ No devenv.nix file found in the current directory."
  echo "To create one, run '@defaultPackageName@-initDevenv'"
  exit 1
fi
