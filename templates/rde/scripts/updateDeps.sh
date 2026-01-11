#!/usr/bin/env bash
set -euo pipefail

echo "🔄 Updating project dependencies..."

# Ensure we're in the repository root
if [[ ! -f "flake.nix" ]]; then
  # Try to find git root
  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    cd "$(git rev-parse --show-toplevel)"
    if [[ ! -f "flake.nix" ]]; then
      echo "❌ Error: flake.nix not found in repository root"
      exit 1
    fi
  else
    echo "❌ Error: Not in a git repository and flake.nix not found"
    exit 1
  fi
fi

# Fetch latest R version from rstats-on-nix
# This command chain: downloads CSV, extracts last line, gets 4th field (date), removes quotes
echo "📡 Fetching latest R version from rstats-on-nix..."
RVER=$( wget -qO- 'https://raw.githubusercontent.com/ropensci/rix/refs/heads/main/inst/extdata/available_df.csv' | tail -n 1 | head -n 1 | cut -d',' -f4 | tr -d '"' )

# Validate RVER matches YYYY-MM-DD format
if [[ ! "$RVER" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "❌ Error: Failed to fetch valid R version date. Got: '$RVER'"
  exit 1
fi

echo "✅ R date is $RVER"

# Create backup of flake.nix before modifying
cp flake.nix flake.nix.backup

# Update rixpkgs date in flake.nix
if sed -i "s|rixpkgs.url = \"github:rstats-on-nix/nixpkgs/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\";|rixpkgs.url = \"github:rstats-on-nix/nixpkgs/$RVER\";|" flake.nix; then
  echo "✅ Updated rixpkgs date in flake.nix"
  rm flake.nix.backup
else
  echo "⚠️  Warning: Failed to update flake.nix, restoring backup"
  mv flake.nix.backup flake.nix
fi

nix flake update
echo "✅ Flake inputs updated"

# Update Python dependencies if pyproject.toml exists and uv is available
if [[ -f "pyproject.toml" ]]; then
  if command -v uv >/dev/null 2>&1; then
    uv sync --upgrade
    echo "✅ Python dependencies updated"
  else
    echo "ℹ️  pyproject.toml found but uv command not available, skipping Python update"
  fi
fi

# Update Julia dependencies if Project.toml exists and julia is available
if [[ -f "Project.toml" ]]; then
  if command -v @defaultPackageName@-jl >/dev/null 2>&1; then
    @defaultPackageName@-jl -e "using Pkg; Pkg.update()"
    echo "✅ Julia dependencies updated"
  else
    echo "ℹ️  Project.toml found but @defaultPackageName@-jl command not available, skipping Julia update"
  fi
fi

# Update devenv dependencies if devenv.nix exists and devenv is available
if [[ -f "devenv.nix" ]]; then
  if command -v devenv >/dev/null 2>&1; then
    devenv update
    echo "✅ Devenv dependencies updated"
  else
    echo "ℹ️  devenv.nix found but devenv command not available, skipping devenv update"
  fi
fi

echo "🎉 All dependencies updated!"
