# Research Development Environment (RDE) Template

This is a Nix flake template for setting up research development environments with support for R, Python, and Julia.

## Structure

The template is organized into several directories for better maintainability:

```
templates/rde/
├── flake.nix              # Main flake configuration (258 lines)
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
│   └── shell-hook.nix    # Dev shell welcome message
└── scripts/               # Shell scripts
    ├── initPython.sh     # Initialize Python project
    ├── initProject.sh    # Initialize project structure
    ├── updateDeps.sh     # Update all dependencies
    └── activateDevenv.sh # Activate devenv shell
```

## Benefits of This Structure

1. **Modularity**: Each component is in its own file, making it easier to understand and modify
2. **Maintainability**: Changes to one language or feature don't affect others
3. **Readability**: Main flake.nix is now ~258 lines instead of 688 (62.5% reduction)
4. **Reusability**: Individual modules can be easily reused or replaced
5. **Testability**: Smaller files are easier to test and debug

## Configuration

Edit the `config` section in `flake.nix` to customize:

- `defaultPackageName`: Name of your project/package
- `enabledLanguages`: Enable/disable R, Python, Julia support
- `enabledPackages`: Enable additional features like devenv
- `theme`: Configure Neovim color scheme

## Extending

To add new functionality:

- **New packages**: Add overlays in `overlays/`
- **New commands**: Add host configs in `hosts/`
- **New scripts**: Add shell scripts in `scripts/`
- **New languages**: Create new host and overlay files
- **Modify shell welcome**: Edit `lib/shell-hook.nix`

## Usage

Use this template with:

```bash
nix flake init -t github:dwinkler1/np#rde
```

Then run `direnv allow` or enter the dev shell with `nix develop`.
