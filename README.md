# Nix Project Templates (np)

A collection of Nix flake templates for reproducible development environments.

## Templates

### RDE (Research Development Environment)

The default template for data science and research projects with support for R, Python, and Julia.

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

- `.github/workflows/check.yml` - Comprehensive functionality tests (Ubuntu)
- `.github/workflows/check_macos.yml` - macOS compatibility tests
- `.github/workflows/update.yml` - Automated dependency updates

## Usage

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
