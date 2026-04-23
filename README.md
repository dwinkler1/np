# Nix Project Templates (np)

A collection of Nix flake templates for reproducible development environments.

## Templates

### ED (Editor)

A simple Neovim-based development environment with optional language support.

**Quick start:**
```bash
nix flake init -t github:dwinkler1/np#ed
nix develop
vv  # Launch Neovim (custom binary name)
```

**Features:**
- ✨ Lightweight Neovim configuration
- 🔧 Configurable language support (Python, R, Julia, Nix)
- 📦 Reproducible with Nix
- 🎨 Custom theming (Kanagawa by default)
- 🔔 Mini-notify plugin for notifications

**Default configuration:**
- Nix support enabled
- Custom binary: `vv`
- Includes: cowsay, updateR utility

### RDE (Research Development Environment)

A comprehensive template for data science and research projects with support for R, Python, and Julia.

**Quick start:**
```bash
nix flake init -t github:dwinkler1/np#rde
nix develop
```

**Features:**
- 🔬 Multi-language support (R, Python, Julia)
- 📦 Reproducible with Nix
- 🎨 Neovim-based IDE with LSP support
- 📊 Research-focused workflows
- 🔧 Modular and customizable

See [templates/rde/README.md](templates/rde/README.md) for full documentation.

## CI/CD

All templates are automatically tested to ensure functionality:

- **Build Tests**: Templates build successfully on Linux and macOS
- **Functionality Tests**: All commands and language support are verified
- **Configuration Tests**: Multiple configurations (R, Python, Julia) are tested
- **Automated Updates**: Dependencies are updated daily via automated PRs

### CI Workflows

**RDE Template:**
- `.github/workflows/check.yml` - Comprehensive functionality tests for RDE (Ubuntu)
  - Basic build and flake checks
  - Dev shell functionality
  - R command availability and functionality
  - Neovim integration
  - Utility commands (p-initProject, p-updateDeps)
  - Separate jobs for Python and Julia configurations

**ED Template:**
- `.github/workflows/check_ed.yml` - Comprehensive functionality tests for ED (Ubuntu)
  - Basic build and flake checks
  - Dev shell functionality
  - Neovim (vv) command tests
  - updateR utility tests
  - Extra packages (cowsay) verification
  - Separate jobs for Python, R, Julia, and multi-language configurations

**Cross-platform:**
- `.github/workflows/check_macos.yml` - macOS compatibility tests for both templates
- `.github/workflows/update.yml` - Automated dependency updates

## Usage

### ED Template

1. **Initialize a new project:**
   ```bash
   nix flake init -t github:dwinkler1/np#ed
   ```

2. **Enter development environment:**
   ```bash
   nix develop
   # or with direnv
   echo "use flake" > .envrc && direnv allow
   ```

3. **Start editing:**
   ```bash
   vv              # Launch Neovim
   updateR         # Update R packages (when R is enabled)
   cowsay "Hello!" # Fun utility included
   ```

4. **Enable languages:**
   Edit `flake.nix` and change `false` to `true` in the `cats` section:
   ```nix
   cats = {
     python = true;  # Enable Python support
     r = true;       # Enable R support
     julia = true;   # Enable Julia support
   };
   ```

### RDE Template

1. **Initialize a new project:**
   ```bash
   nix flake init -t github:dwinkler1/np#rde
   ```

2. **Enter development environment:**
   ```bash
   nix develop
   # or with direnv
   echo "use flake" > .envrc && direnv allow
   ```

3. **Start working:**
   ```bash
   p-initProject  # Create project structure
   p              # Launch Neovim
   ```

## Contributing

Contributions are welcome! Please ensure:
- All templates pass CI tests
- Documentation is updated for new features
- Code follows existing patterns

## License

See [LICENSE](LICENSE) file for details.
