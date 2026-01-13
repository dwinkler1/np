# Research Development Environment (RDE) Template

A modular Nix flake template for reproducible research environments with support for R, Python, and Julia. Designed for data science, statistical analysis, and computational research.

## Features

- 🔬 **Multi-language support**: R, Python, Julia with integrated tooling
- 📦 **Reproducible**: Nix ensures consistent environments across machines
- 🎨 **Neovim-based**: Powerful editor with LSP, completion, and more
- 📊 **Research-focused**: Pre-configured for data analysis workflows
- 🔧 **Modular**: Enable only the languages you need
- 📝 **Documented**: Comprehensive inline documentation

## Quick Start

### Installation

```bash
# Initialize a new project with this template
nix flake init -t github:dwinkler1/np#rde

# Enter the development environment
nix develop

# Or use direnv for automatic activation
echo "use flake" > .envrc
direnv allow
```

### First Steps

```bash
# Initialize project structure (creates directories, git repo)
p-initProject

# Enable Python (if needed)
# Edit flake.nix: set enabledLanguages.python = true

# Initialize Python project
p-initPython

# Update all dependencies
p-updateDeps
```

## Structure

The template is organized into several directories for better maintainability:

```
templates/rde/
├── flake.nix              # Main flake configuration (261 lines)
├── README.md              # This file
├── overlays/              # Nix overlays for packages
│   ├── r.nix             # R packages configuration
│   ├── python.nix        # Python packages configuration
│   ├── rix.nix           # rstats-on-nix integration
│   ├── theme.nix         # Neovim theme configuration
│   └── project-scripts.nix # Project initialization scripts
├── hosts/                 # Host/command configurations
│   ├── default.nix       # Merges all host configs
│   ├── python.nix        # Python commands (marimo, ipy, etc.)
│   ├── julia.nix         # Julia commands (jl, pluto, etc.)
│   ├── r.nix             # R commands
│   └── utils.nix         # Utility commands (initProject, etc.)
├── lib/                   # Helper functions
│   ├── shell-hook.nix    # Dev shell welcome message
│   └── mini-notify-config.lua # Neovim notification filtering
└── scripts/               # Shell scripts
    ├── initPython.sh     # Initialize Python project
    ├── initProject.sh    # Initialize project structure
    ├── updateDeps.sh     # Update all dependencies
    └── activateDevenv.sh # Activate devenv shell
```

## Configuration

Edit the `config` section in `flake.nix` to customize your environment:

### Basic Settings

```nix
config = rec {
  # Name for your project commands (e.g., myproject-r, myproject-py)
  defaultPackageName = "p";

  # Enable/disable language support
  enabledLanguages = {
    julia = false;   # Julia with Pluto notebooks
    python = false;  # Python with uv package manager
    r = true;        # R with tidyverse and friends
  };

  # Additional features
  enabledPackages = {
    gitPlugins = enabledLanguages.r;  # R.nvim plugin
    devenv = false;                    # Additional dev environment
  };

  # Neovim color scheme
  theme = rec {
    colorscheme = "kanagawa";  # cyberdream, onedark, tokyonight, kanagawa
    background = "dark";       # dark or light
  };
};
```

### Language-Specific Configuration

#### R Configuration

Edit `overlays/r.nix` to add/remove R packages:

```nix
reqPkgs = with final.rpkgs.rPackages; [
  tidyverse      # Add your packages here
  data_table
  # ... more packages
];
```

Or create `r-packages.nix` in your project:

```nix
rpkgs: with rpkgs.rPackages; [
  ggplot2
  dplyr
]
```

#### Python Configuration

Python packages are managed via `uv`:

```bash
# Add packages to your project
uv add numpy pandas matplotlib

# Or edit pyproject.toml directly
```

#### Julia Configuration

Julia packages use the built-in package manager:

```bash
# In Julia REPL (p-jl)
using Pkg
Pkg.add("DataFrames")
```

## Available Commands

Commands are prefixed with your `defaultPackageName` (default: `p`).

### Editor

- `p` or `p-pvim`: Launch Neovim
- `p-g`: Launch Neovide (GUI)

### R (when enabled)

- `p-r`: R console with pre-loaded packages
- Includes: tidyverse, data.table, languageserver, quarto

### Python (when enabled)

- `p-py`: Python interpreter
- `p-ipy`: IPython REPL (enhanced interactive shell)
- `p-marimo`: Marimo notebooks (reactive notebooks)
- `p-initPython`: Initialize Python project with uv

### Julia (when enabled)

- `p-jl`: Julia REPL with project environment
- `p-pluto`: Pluto.jl notebooks (reactive notebooks)
- `p-initJl`: Initialize Julia project

### Utilities

- `p-initProject`: Create project directory structure
- `p-updateDeps`: Update all dependencies (R, Python, Julia, flake)

## Project Workflow

### 1. Initialize Project

```bash
# Create standardized directory structure
p-initProject

# Creates:
# - data/{raw,processed,interim}/
# - docs/
# - figures/
# - tables/
# - src/{analysis,data_prep,explore,utils}/
# - .gitignore
# - README.md
```

### 2. Set Up Language Environment

**For R:**
```bash
# R is enabled by default
# Just start using it
p-r
```

**For Python:**
```bash
# 1. Enable in flake.nix
# 2. Initialize project
p-initPython
# 3. Add packages
uv add numpy pandas scikit-learn
```

**For Julia:**
```bash
# 1. Enable in flake.nix
# 2. Initialize project
p-initJl
# 3. Packages are managed in Julia REPL
```

### 3. Development

```bash
# Start Neovim
p

# Or use notebooks
p-marimo          # Python notebooks
p-pluto           # Julia notebooks

# R scripts work with p (Neovim has R support)
```

### 4. Keep Dependencies Updated

```bash
# Update everything at once
p-updateDeps

# This updates:
# - R packages (rixpkgs snapshot)
# - Python packages (via uv)
# - Julia packages (via Pkg)
# - Flake inputs
```

## Benefits of This Structure

1. **Modularity**: Each component is in its own file, making it easier to understand and modify
2. **Maintainability**: Changes to one language or feature don't affect others
3. **Readability**: Main flake.nix is ~261 lines instead of 688 (62% reduction)
4. **Reusability**: Individual modules can be easily reused or replaced
5. **Testability**: Smaller files are easier to test and debug
6. **Documentation**: Comprehensive inline comments explain how everything works

## Extending the Template

### Add New R Packages

**System-wide** (edit `overlays/r.nix`):
```nix
reqPkgs = with final.rpkgs.rPackages; [
  tidyverse
  yourNewPackage  # Add here
];
```

**Project-specific** (create `r-packages.nix`):
```nix
rpkgs: with rpkgs.rPackages; [
  projectSpecificPackage
]
```

### Add New Python Packages

```bash
uv add package-name
```

### Add New Commands

Edit the appropriate file in `hosts/`:
- `hosts/python.nix` - Python commands
- `hosts/julia.nix` - Julia commands
- `hosts/r.nix` - R commands
- `hosts/utils.nix` - General utilities

### Add New Scripts

1. Create script in `scripts/`
2. Add to `overlays/project-scripts.nix`
3. Add to appropriate host file

### Customize Neovim

The template uses a pre-configured Neovim (nixCats). To customize:
- Edit theme in `config.theme` section
- Add plugins in `flake.nix` categoryDefinitions
- Modify LSP settings in `categoryDefinitions.lspsAndRuntimeDeps`

## Troubleshooting

### Nix Build Fails

```bash
# Update flake inputs
nix flake update

# Clear cache
nix-collect-garbage
```

### Python Packages Not Found

```bash
# Sync environment
uv sync

# Or re-initialize
p-initPython
```

### R Packages Not Available

```bash
# Update R snapshot
p-updateDeps

# Or check overlays/r.nix for package name
```

## CI and Testing

This template is automatically tested on every change to ensure all functionality works correctly. The CI workflow (`.github/workflows/check.yml`) runs comprehensive tests including:

### Default Configuration Tests (R enabled)
- ✅ Template builds successfully
- ✅ Flake check passes
- ✅ Development shell enters without errors
- ✅ Neovim launches in headless mode
- ✅ R console is available and runs code
- ✅ Utility commands (initProject, updateDeps) are available
- ✅ Project structure creation works correctly

### Python Configuration Tests
- ✅ Template builds with Python enabled
- ✅ Python commands (p-py, p-ipy, p-initPython) are available
- ✅ Python interpreter launches and executes code

### Julia Configuration Tests
- ✅ Template builds with Julia enabled
- ✅ Julia commands (p-jl, p-initJl) are available
- ✅ Julia REPL launches and executes code

The CI runs on:
- Every push to template files (`.nix`, `.sh`, `.lua`, `flake.lock`)
- Every pull request affecting the template
- Manual dispatch for testing

This ensures that users can confidently use the template knowing that all advertised functionality has been verified.

## Related Documentation

- [REFACTORING.md](REFACTORING.md) - Technical details about the modular structure
- [SUMMARY.md](SUMMARY.md) - Metrics and comparison with original template

## Usage

Use this template with:

```bash
nix flake init -t github:dwinkler1/np#rde
```

Then run `direnv allow` or enter the dev shell with `nix develop`.
