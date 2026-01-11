#!/usr/bin/env bash
set -euo pipefail

echo "🔄 Updating project dependencies..."

RVER=$( wget -qO- 'https://raw.githubusercontent.com/ropensci/rix/refs/heads/main/inst/extdata/available_df.csv' | tail -n 1 | head -n 1 | cut -d',' -f4 | tr -d '"' ) &&\

sed -i  "s|rixpkgs.url = \"github:rstats-on-nix/nixpkgs/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\";|rixpkgs.url = \"github:rstats-on-nix/nixpkgs/$RVER\";|" flake.nix
echo "✅ R date is $RVER"

nix flake update
echo "✅ Flake inputs updated"

if [[ -f "pyproject.toml" ]]; then
  uv sync --upgrade
  echo "✅ Python dependencies updated"
fi

if [[ -f "Project.toml" ]]; then
  @defaultPackageName@-jl -e "using Pkg; Pkg.update()"
  echo "✅ Julia dependencies updated"
fi

if [[ -f "devenv.nix" ]]; then
  devenv update
  echo "✅ Devenv dependencies updated"
fi

echo "🎉 All dependencies updated!"
