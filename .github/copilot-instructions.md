# GitHub Copilot Instructions for np Repository

## Repository Overview

This repository provides Nix flake templates for setting up Research Development Environments (RDE). The primary template is located in `templates/rde/` and is designed for data science and research projects supporting R, Python, and Julia.

## Project Structure

- `flake.nix` - Root flake defining available templates
- `templates/rde/` - Main RDE template with Neovim-based development environment
  - `flake.nix` - Template flake configuration with language support and tooling
  - `flake.lock` - Locked dependencies for reproducibility
  - `.envrc` - direnv configuration for automatic environment loading
- `.github/workflows/` - CI/CD workflows for testing and updates
  - `check.yml` - Tests RDE template on Ubuntu
  - `check_macos.yml` - Tests RDE template on macOS
  - `update.yml` - Automated daily dependency updates

## Key Technologies

- **Nix Flakes**: Reproducible development environments
- **nixCats**: Custom Neovim configuration framework
- **direnv**: Automatic environment loading
- **Cachix**: Binary cache for faster builds (using `rde`, `rstats-on-nix`, and `nix-community` caches)

## Language Support

The RDE template supports multiple languages, controlled via `config.enabledLanguages` in `templates/rde/flake.nix`:

- **R**: R wrapper, Quarto, air-formatter, language server, and custom R packages via overlays
- **Python**: Python 3, basedpyright LSP, UV package manager
- **Julia**: Julia REPL with Pluto.jl support

## Development Commands

The template provides project-specific commands (prefix with package name, default is `p`):

- `p` - Launch Neovim
- `p-g` - Launch Neovide GUI
- `p-initProject` - Initialize project structure (data/, src/, docs/)
- `p-updateDeps` - Update all dependencies (flake inputs, R packages, Python packages)
- `p-r` - Launch R console
- `p-py` / `p-ipy` - Launch Python/IPython REPL
- `p-marimo` - Launch Marimo notebook
- `p-jl` - Launch Julia REPL
- `p-pluto` - Launch Pluto.jl notebook
- `p-devenv` - Devenv integration (when enabled)

## Nix Flake Conventions

### Configuration Structure

The RDE template uses a centralized `config` object at the top of `flake.nix`:

```nix
config = rec {
  defaultPackageName = "p";
  enabledLanguages = { julia = false; python = false; r = true; };
  enabledPackages = { gitPlugins = enabledLanguages.r; devenv = false; };
  theme = { colorscheme = "kanagawa"; background = "dark"; };
};
```

### Overlays Pattern

The template uses multiple overlays to extend nixpkgs:

- `rOverlay` - Adds R packages via rix/rstats-on-nix
- `pythonOverlay` - Configures Python packages
- `rixOverlay` - Integrates R package snapshots from rstats-on-nix
- `projectScriptsOverlay` - Custom shell scripts for project management
- `extraPkgOverlay` - Additional theme and plugin configuration

### Package Categories

nixCats uses categories to organize functionality:

- `lspsAndRuntimeDeps` - Language servers and runtime dependencies
- `startupPlugins` - Neovim plugins loaded at startup
- `optionalPlugins` - Plugins loaded on demand
- `environmentVariables` - Language-specific environment setup
- `extraWrapperArgs` - Additional wrapper arguments (e.g., unset PYTHONPATH for Python)

## Testing & CI/CD

### Local Testing

```bash
# Build the RDE template
nix build ./templates/rde

# Check the RDE template
nix flake check ./templates/rde

# Enter development shell
nix develop ./templates/rde
```

### CI Workflows

- **check.yml**: Runs on pushes to `templates/rde/flake.lock`, builds and checks the template on Ubuntu
- **check_macos.yml**: Tests on macOS when `update_rde` branch is pushed
- **update.yml**: Daily cron job that updates dependencies via `p-updateDeps` and creates PRs

## Dependency Management

### R Packages

R packages are managed through rstats-on-nix pinned snapshots. The date is specified in the `rixpkgs.url` input:

```nix
rixpkgs.url = "github:rstats-on-nix/nixpkgs/2025-12-15";
```

Custom R packages can be added in `rOverlay` or via `r-packages.nix` file.

### Python Packages

Python packages use UV for management with nixpkgs Python as the interpreter:

- Environment variables force UV to use nix Python: `UV_PYTHON_DOWNLOADS = "never"` and `UV_PYTHON = pkgs.python.interpreter`
- PYTHONPATH is explicitly unset via `extraWrapperArgs`

### Flake Inputs

Dependencies are tracked in `flake.lock`. Key inputs include:

- `nixpkgs` - NixOS 25.11
- `rixpkgs` - R package snapshots from rstats-on-nix
- `nixCats` - Custom Neovim configuration framework
- `fran` - Extra R packages overlay
- Plugin inputs for R.nvim ecosystem

## Coding Style & Conventions

1. **Nix Code**:
   - Use `rec` for recursive attribute sets when needed
   - Prefer `let...in` for local bindings
   - Use `lib.optional` and `lib.optionalString` for conditional inclusion
   - Keep configuration at the top of the file for easy customization

2. **Shell Scripts** (in overlays):
   - Always use `set -euo pipefail` for safety
   - Provide user-friendly output with emojis and clear messages
   - Check for existing files/directories before creating

3. **Workflows**:
   - Use `workflow_dispatch` for manual triggering
   - Configure concurrency to cancel in-progress runs
   - Use Cachix for binary caching with multiple caches

## Common Patterns

### Adding a New Language

1. Add to `config.enabledLanguages`
2. Create overlay for language-specific packages
3. Add to `categoryDefinitions.lspsAndRuntimeDeps`
4. Add command aliases in `packageDefinitions.hosts`
5. Update `shellHook` with available commands

### Adding Custom Scripts

Add to `projectScriptsOverlay`:

```nix
myScript = prev.writeShellScriptBin "myScript" ''
  #!/usr/bin/env bash
  set -euo pipefail
  # script content
'';
```

### Plugin Integration

For git-based plugins:
1. Add flake input with `flake = false`
2. Reference in nixCats inputs
3. Add to `startupPlugins` or `optionalPlugins` categories

## Important Notes

- The template creates a `.gitignore` that excludes data files by default
- R packages are installed to project-local `.Rlibs/` directory
- Python UV is configured to never download Python, always using nixpkgs version
- The template supports multiple platforms: x86_64-linux, aarch64-linux, aarch64-darwin
- Neovim is wrapped with language-specific environment variables and PATH additions

## File Generation

When asked to initialize projects or generate common files, follow the patterns in:
- `initProjectScript` for project structure
- `.gitignore` template for what to exclude
- `README.md` template for documentation structure
