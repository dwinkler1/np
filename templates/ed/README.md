# Project Editor

A per-project Neovim wrapper built with [nix-wrapper-modules](https://birdeehub.github.io/nix-wrapper-modules/) and [nvimConfig](https://github.com/dwinkler1/nvimConfig).

## Setup

The flake provides two entry points:

| Command | What you get |
|---|---|
| `direnv allow` / `nix develop` | **(Recommended)** A shell with `nv` and all enabled language toolchains (R, Python, Julia, Quarto) on `PATH`. |
| `nix run` | Launches only the `nv` editor. Language toolchains (R, Python, etc.) are **not** on `PATH`. |

### With direnv (recommended)

```bash
direnv allow   # enter the devShell automatically
nv             # launch the pre-configured Neovim
R              # R REPL is available (if enabled in flake.nix)
```

### Without direnv

```bash
nix develop    # enter the devShell manually
nv             # launch Neovim
R              # R REPL is available (if enabled in flake.nix)
```

> **Why `nix run` only gives the editor:** The flake's `packages.default` is the wrapped Neovim binary. Language toolchains (R, radian, quarto, etc.) live in `devShells.default`. Use `nix develop` (or `direnv allow`) to get the full environment.

## Configuration

The `flake.nix` is the single source of truth. Key knobs:

| Option | What it controls |
|---|---|
| `cats` | Toggle language support (nix, r, python, julia, etc.) |
| `settings.lang_packages.<lang>` | Language-specific packages installed in the wrapper |
| `settings.colorscheme` | Neovim colorscheme |
| `settings.background` | `"dark"` or `"light"` |
| `settings.wrapRc` | When `true`, init.lua is embedded (rebuild to change); when `false`, init.lua is external (reload without rebuild) |
| `binName` | The wrapper binary name (`nv` by default) |
| `env` | Environment variables set in the wrapper |
| `extraPackages` | Extra system packages available in the wrapper's PATH |
| `specs.extraLua` | Inject lazy.nvim plugin specs |

### Adding packages without editing flake.nix

Create any of these optional files in the project root to add dependencies without modifying `flake.nix`:

- **`python-packages.nix`** — receives `python3Packages`, return a list of packages:
  ```nix
  p: with p; [ numpy scipy ]
  ```

- **`r-packages.nix`** — receives `rpkgs` (includes `rPackages`), return a list:
  ```nix
  p: with p.rPackages; [ ggplot2 data.table ]
  ```

- **`julia-packages.nix`** — no arguments, return a list of package name strings:
  ```nix
  [ "DataFrames" "Plots" ]
  ```

## Formatting

```bash
nix fmt
```

Uses `nixfmt-rfc-style` pinned via the flake's `formatter` output.
