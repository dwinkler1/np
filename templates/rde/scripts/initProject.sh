#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="${1:-@defaultPackageName@}"

echo "🚀 Setting up project: $PROJECT_NAME"

# Create directory structure
directories=(
  "data/raw"
  "data/processed"
  "data/interim"
  "docs"
  "figures"
  "tables"
  "src/analysis"
  "src/data_prep"
  "src/explore"
  "src/utils"
)

for dir in "${directories[@]}"; do
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    echo "✓ Created $dir/"
  fi
done

# Create essential files
if [[ ! -f "README.md" ]]; then
  cat > README.md << 'EOF'
# RDE

## Project Structure
- `data/`: Data files (gitignored)
- `docs/`: Documentation
- `figures/`: Output figures
- `tables/`: Output tables
- `src/`: Source code

EOF
fi

# Initialize git
if [[ ! -d ".git" ]]; then
  git init
  echo "✓ Initialized Git repository and added: flake.nix, flake.lock"
fi
# Check if files are already staged/tracked before adding
if ! git diff --cached --name-only | grep -q "flake.nix\|flake.lock" &&
   ! git ls-files --error-unmatch flake.nix flake.lock >/dev/null 2>&1; then
  echo "✓ Adding flake.nix, flake.lock to Git repository"
  git add flake.nix flake.lock
else
  echo "✓ flake.nix, flake.lock already tracked/staged in Git"
fi
# Create .gitignore
if [[ ! -f ".gitignore" ]]; then
  cat > .gitignore << 'EOF'
# Data files
data/
*.csv
*.docx
*.xlsx
*.parquet

# R specific
.Rproj.user/
.Rhistory
.RData
.Ruserdata
*.Rproj
.Rlibs/

# Python specific
__pycache__/
*.pyc
.pytest_cache/
.venv/

# Jupyter
.ipynb_checkpoints/

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db

# Devenv
.devenv*
devenv.local.nix

# direnv
.direnv

# pre-commit
.pre-commit-config.yaml
EOF
fi

echo "✅ Project setup completed successfully!"
