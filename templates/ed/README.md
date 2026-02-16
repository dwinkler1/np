# ED Template - Simple Editor Environment

A lightweight, customizable Neovim-based development environment with optional language support for Python, R, Julia, and Nix.

## Features

- ✨ **Lightweight**: Minimal configuration, fast startup
- 🔧 **Configurable**: Enable only the languages you need
- 📦 **Reproducible**: Nix-based environment management
- 🎨 **Themed**: Beautiful Kanagawa colorscheme (customizable)
- 🔔 **Notifications**: Mini-notify plugin for user feedback

## Quick Start

```bash
# Initialize a new project with the ED template
nix flake init -t github:dwinkler1/np#ed

# Enter the development environment
nix develop

# Launch Neovim
vv
```

## Configuration

The ED template uses a centralized configuration structure at the top of `flake.nix`:

```nix
cats = {
  clickhouse = false;
  gitPlugins = false;
  julia = false;
  lua = false;
  markdown = false;
  nix = true;        # Enabled by default
  optional = false;
  python = false;
  r = false;
};
```

### Enabling Languages

To enable support for a specific language, edit `flake.nix` and set the corresponding cat to `true`:

#### Python
```nix
cats = {
  python = true;
  # ... other settings
};
```

Includes: Python 3, duckdb, polars packages by default

#### R
```nix
cats = {
  r = true;
  # ... other settings
};
```

Includes: fixest package by default

#### Julia
```nix
cats = {
  julia = true;
  # ... other settings
};
```

Includes: StatsBase package by default

### Custom Package Files

You can specify additional packages by creating these files in your project:

- `python-packages.nix` - Additional Python packages
  ```nix
  p: with p; [
    numpy
    pandas
    # ... more packages
  ]
  ```

- `r-packages.nix` - Additional R packages
  ```nix
  p: with p.rPackages; [
    ggplot2
    dplyr
    # ... more packages
  ]
  ```

- `julia-packages.nix` - Additional Julia packages
  ```nix
  [
    "DataFrames"
    "Plots"
    # ... more packages
  ]
  ```

## Available Commands

### Neovim
- `vv` - Launch Neovim (custom binary name)
- `vv --headless` - Run Neovim in headless mode for scripting

### Utilities
- `updateR` - Update R package snapshots from rstats-on-nix
- `cowsay` - Fun ASCII art text formatter (included as example)

## Customization

### Binary Name

The default binary name is `vv`. To change it, edit the `binName` in `flake.nix`:

```nix
binName = "myeditor";  # Changes command from 'vv' to 'myeditor'
```

### Colorscheme

Change the colorscheme in the settings section:

```nix
settings = {
  colorscheme = "kanagawa";  # or "gruvbox", "tokyonight", etc.
  background = "dark";        # or "light"
  # ...
};
```

### Extra Packages

Add more system packages in the `extraPackages` section:

```nix
extraPackages = with pkgs; [
  cowsay
  ripgrep
  fd
  # ... more packages
];
```

### Welcome Message

The template includes a welcome notification. Customize it in the `specs.extraLua` section:

```nix
config = ''
  require("mini.notify").setup()
  vim.notify = MiniNotify.make_notify()
  vim.notify("Welcome to ${name}!")
'';
```

## Environment Variables

The template sets the following environment variables:

- `IS_PROJECT_EDITOR=1` - Indicates you're in the project editor environment
- `R_LIBS_USER=./.nvimcom` - Project-local R package directory

## Language Package Management

### Replace vs Merge

By default, language packages are **replaced** rather than merged with base packages. This is controlled by:

```nix
let
  replace = pkgs.lib.mkForce;
in {
  lang_packages = {
    python = replace ([...]);  # Replaces base packages
    r = replace ([...]);       # Replaces base packages
    julia = replace ([...]);   # Replaces base packages
  };
}
```

To **merge** with base packages instead, remove the `replace` wrapper:

```nix
lang_packages = {
  python = (with pkgs.python3Packages; [...]);
  # ...
};
```

## Development Shell

The development shell provides access to the Neovim package plus additional utilities:

```bash
nix develop  # Enter the dev shell
```

Available in dev shell:
- `vv` - The configured Neovim
- `updateR` - Update R packages (when R support is enabled)
- All packages listed in `extraPackages`

## Testing

The ED template has comprehensive CI/CD tests:

### Automated Tests (`.github/workflows/check_ed.yml`)

1. **Basic Tests** (Ubuntu)
   - Build verification
   - Flake check
   - Dev shell entry
   - Neovim launch and version check
   - Utility commands availability

2. **Language-Specific Tests**
   - Python configuration: Package imports, code execution
   - R configuration: Package loading, code execution
   - Julia configuration: Version check, code execution
   - Multi-language: All languages enabled together

3. **macOS Tests** (`.github/workflows/check_macos.yml`)
   - Build verification on macOS
   - Basic functionality tests

## Tips

1. **Use direnv for automatic environment loading:**
   ```bash
   echo "use flake" > .envrc
   direnv allow
   ```

2. **Pin specific package versions** by editing `flake.lock`:
   ```bash
   nix flake update  # Update all inputs
   nix flake lock --update-input nixpkgs  # Update specific input
   ```

3. **Check what's included in your build:**
   ```bash
   nix path-info -Sh ./result
   ```

4. **Build for different platforms:**
   ```bash
   nix build .#packages.x86_64-linux.default
   nix build .#packages.aarch64-darwin.default
   ```

## Comparison with RDE Template

| Feature | ED Template | RDE Template |
|---------|-------------|--------------|
| **Complexity** | Lightweight | Comprehensive |
| **Binary Name** | `vv` | `p` |
| **Project Structure** | Manual | `p-initProject` command |
| **Language Support** | Optional (Python, R, Julia, Nix) | Built-in (R default, Python/Julia optional) |
| **Research Tools** | None | Quarto, Marimo, Pluto.jl |
| **Package Management** | updateR | p-updateDeps (comprehensive) |
| **Use Case** | Simple editing, lightweight projects | Research, data science, complex projects |

## Contributing

When modifying the ED template, please ensure:

1. All tests pass in `.github/workflows/check_ed.yml`
2. The template builds on both Linux and macOS
3. Documentation is updated to reflect changes
4. Changes follow the existing code patterns

## License

See [LICENSE](../../LICENSE) file for details.
