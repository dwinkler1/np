{
  description = "New Project";

  outputs = {
    self,
    nixpkgs,
    nixCats,
    ...
  } @ inputs: let
    #######################
    ### PROJECT CONFIG ####
    #######################
    ## Set options below:
    config = rec {
      ## Set project name
      defaultPackageName = "p";
      ## Enable languages
      enabledLanguages = {
        julia = false;
        python = false;
        r = false;
      };
      ## Enable packages
      enabledPackages = {
        ## Plugins loaded via flake input
        ### Always enable when R is enabled
        ### You can use your own R installation and just enable the plugin
        gitPlugins = enabledLanguages.r;
      };
      theme = rec {
        ## set colortheme and background here
        ### "cyberdream", "ondeark", and "tokyonight" are pre-installed
        colorscheme = "kanagawa";
        background = "dark";
        ## Add other colortheme packages and config here
        ## The default is a best guess
        extraColorschemePackage = rec {
          name = colorscheme;
          extraLua = ''
            vim.notify("Loading ${colorscheme} with extra config...")
            require('${name}').setup({
              commentStyle = {italic = false},
              keywordStyle = {italic = false},
              theme = 'dragon'
            })
          '';
          plugin = name + "-nvim";
        };
      };
    };
    # R packages
    rOverlay = final: prev: let
      reqPkgs = with final.rpkgs.rPackages; [
        broom
        data_table
        janitor
        languageserver
        reprex
        styler
        tidyverse
        (buildRPackage {
          name = "nvimcom";
          src = inputs.plugins-r;
          sourceRoot = "source/nvimcom";
          buildInputs = with prev.rpkgs; [
            R
            stdenv.cc.cc
            gnumake
          ];
          propagatedBuildInputs = [];
        })
      ];
    in {
      quarto = final.rpkgs.quarto.override {extraRPackages = reqPkgs;};
      rWrapper = final.rpkgs.rWrapper.override {packages = reqPkgs;};
    };

    # Python packages
    pythonOverlay = final: prev: {
      python = prev.python3.withPackages (pyPackages:
        with pyPackages; [
          requests
        ]);
    };

    ###################################
    ## ⬆️ BASIC CONFIG ABOVE HERE ⬆️ ##
    ###################################

    rixOverlay = final: prev: {rpkgs = inputs.rixpkgs.legacyPackages.${prev.system};};

    extraPkgOverlay = final: prev: let
      extraTheme = {
        plugin = prev.vimPlugins."${config.theme.extraColorschemePackage.plugin}";
        name = config.theme.extraColorschemePackage.name;
        config = {
          lua = config.theme.extraColorschemePackage.extraLua;
        };
      };
    in {
      inherit extraTheme;
    };

    projectScriptsOverlay = final: prev: let
      initPython = ''
        #!/usr/bin/env bash
        set -euo pipefail
        if [[ ! -f "pyproject.toml" ]]; then
          echo "🐍 Initializing UV project..."
          uv init
          echo "📦 Adding IPython and Marimo..."
          uv add ipython
          uv add marimo
          echo "--------------------------------------------------------------------------"
          echo "✅ Python project initialized!"
          echo "run 'uv add PACKAGE' to add more python packages."
          echo "--------------------------------------------------------------------------"
        else
          echo "--------------------------------------------------------------------------"
          echo "🔄 Existing Python project detected."
          echo "📦 Ensuring IPython and Marimo are installed..."
          uv add ipython
          uv add marimo
          echo "Run '${config.defaultPackageName}-updateDeps' to update dependencies."
          echo "--------------------------------------------------------------------------"
        fi
      '';

      initProjectScript = ''
        #!/usr/bin/env bash
        set -euo pipefail

        PROJECT_NAME="''${1:-${config.defaultPackageName}}"

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

        for dir in "''${directories[@]}"; do
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
        EOF
        fi

        echo "✅ Project setup completed successfully!"
      '';

      updateDepsScript = ''
        #!/usr/bin/env bash
        set -euo pipefail

        echo "🔄 Updating project dependencies..."

        if [[ -f "flake.lock" ]]; then
          nix flake update
          echo "✅ Flake inputs updated"
        fi

        if [[ -f "pyproject.toml" ]]; then
          uv sync --upgrade
          echo "✅ Python dependencies updated"
        fi

        if [[ -f "Project.toml" ]]; then
          ${config.defaultPackageName}-jl -e "using Pkg; Pkg.update()"
          echo "✅ Julia dependencies updated"
        fi

        echo "🎉 All dependencies updated!"
      '';
    in {
      initPython = prev.writeShellScriptBin "initPython" initPython;
      initProject = prev.writeShellScriptBin "initProject" initProjectScript;
      updateDeps = prev.writeShellScriptBin "updateDeps" updateDepsScript;
    };
    forSystems = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
    projectConfig = forSystems (
      system: let
        inherit (nixCats) utils;
        inherit (config) defaultPackageName;
        prevPackage = nixCats.packages.${system}.default;
        finalPackage = prevPackage.override (prev: {
          name = config.defaultPackageName;
          dependencyOverlays =
            prev.dependencyOverlays
            ++ [
              (utils.standardPluginOverlay inputs)
              extraPkgOverlay
              rixOverlay
              rOverlay
              pythonOverlay
              projectScriptsOverlay
            ];
          categoryDefinitions = utils.mergeCatDefs prev.categoryDefinitions (
            {
              pkgs,
              settings,
              categories,
              name,
              extra,
              mkPlugin,
              ...
            } @ packageDef: {
              lspsAndRuntimeDeps = {
                project = with pkgs; [
                ];
                julia = with pkgs; [
                  julia-bin
                ];
                python = with pkgs; [
                  python
                  nodejs
                  pyright
                  uv
                ];
                r = with pkgs; [
                  rWrapper
                  quarto
                  air-formatter
                ];
              };

              startupPlugins = {
                project = with pkgs.vimPlugins; [
                  pkgs.extraTheme
                ];
                gitPlugins = with pkgs.neovimPlugins; [
                  {
                    plugin = r;
                    config.lua = "vim.notify('Using project local R plugin')";
                  }
                ];
              };

              optionalPlugins = {
                project = with pkgs.vimPlugins; [
                ];
                gitPlugins = with pkgs.neovimPlugins; [
                  cmp-r
                  cmp-pandoc-references
                ];
              };
              optionalLuaPreInit = {
                project = [
                  ''
                    local predicate = function(notif)
                      if not (notif.data.source == "lsp_progress" and notif.data.client_name == "lua_ls") then
                        return true
                      end
                      -- Filter out some LSP progress notifications from 'lua_ls'
                      return notif.msg:find("Diagnosing") == nil and notif.msg:find("semantic tokens") == nil
                    end
                    local custom_sort = function(notif_arr)
                      return MiniNotify.default_sort(vim.tbl_filter(predicate, notif_arr))
                    end
                    require("mini.notify").setup({ content = { sort = custom_sort } })
                    vim.notify = MiniNotify.make_notify()
                  ''
                ];
              };
              optionalLuaAdditions = {
                project = [
                  "vim.notify('Project loaded: ${name}')"
                ];
              };
              sharedLibraries = {
                project = {
                };
              };

              environmentVariables = {
                project = {
                };
                julia = {
                  JULIA_NUM_THREADS = "auto";
                };
                python = {
                  # Prevent uv from managing Python downloads
                  UV_PYTHON_DOWNLOADS = "never";
                  # Force uv to use nixpkgs Python interpreter
                  UV_PYTHON = pkgs.python.interpreter;
                };
                r = {
                  R_LIBS_USER = "./.Rlibs";
                };
              };

              extraWrapperArgs = {
                python = [
                  "--unset PYTHONPATH"
                ];
              };
            }
          );

          packageDefinitions =
            prev.packageDefinitions
            // {
              "${config.defaultPackageName}" = utils.mergeCatDefs prev.packageDefinitions.n (
                {
                  pkgs,
                  name,
                  ...
                }: {
                  settings = {
                    suffix-path = false;
                    suffix-LD = false;
                    # your alias may not conflict with your other packages.
                    aliases = ["pvim"];
                    hosts = {
                      g = {
                        enable = true;
                        path = {
                          value = "${pkgs.neovide}/bin/neovide";
                          args = [
                            "--add-flags"
                            "--neovim-bin ${name}"
                          ];
                        };
                      };
                      marimo = let
                        marimoInit = ''
                          set -euo pipefail
                          if [[ ! -f "pyproject.toml" ]]; then
                            echo "🐍 Initializing UV project..."
                            uv init
                            echo "📦 Adding Marimo..."
                            uv add marimo
                            echo "--------------------------------------------------------------------------"
                            echo "✅ Python project initialized!"
                            echo "run 'uv add PACKAGE' to add more python packages."
                            echo "--------------------------------------------------------------------------"
                          else
                            echo "--------------------------------------------------------------------------"
                            echo "🔄 Syncing existing project..."
                            uv sync
                            echo "🐍 Launching Marimo..."
                            echo "--------------------------------------------------------------------------"
                          fi
                        '';
                      in {
                        enable = config.enabledLanguages.python;
                        path = {
                          value = "${pkgs.uv}/bin/uv";
                          args = [
                            "--run"
                            "${marimoInit}"
                            "--add-flags"
                            "run marimo edit \"$@\""
                          ];
                        };
                      };
                      py = let
                        ipythonInit = ''
                          set -euo pipefail
                          if [[ ! -f "pyproject.toml" ]]; then
                            echo "🐍 Initializing UV project..."
                            uv init
                            echo "📦 Adding IPython..."
                            uv add ipython
                            echo "--------------------------------------------------------------------------"
                            echo "✅ Python project initialized!"
                            echo "run 'uv add PACKAGE' to add more python packages."
                            echo "--------------------------------------------------------------------------"
                          else
                            echo "--------------------------------------------------------------------------"
                            echo "🔄 Syncing existing project..."
                            echo "📦 Ensuring IPython is installed..."
                            uv add ipython
                            uv sync
                            echo "🐍 Launching IPython..."
                            echo "--------------------------------------------------------------------------"
                          fi
                        '';
                      in {
                        enable = config.enabledLanguages.python;
                        path = {
                          value = "${pkgs.uv}/bin/uv";
                          args = [
                            "--run"
                            "${ipythonInit}"
                            "--add-flags"
                            "run ipython \"$@\""
                          ];
                        };
                      };
                      jl = {
                        enable = config.enabledLanguages.julia;
                        path = {
                          value = "${pkgs.julia-bin}/bin/julia";
                          args = ["--add-flags" "--project=."];
                        };
                      };
                      initJl = {
                        enable = config.enabledLanguages.julia;
                        path = {
                          value = "${pkgs.julia-bin}/bin/julia";
                          args = ["--add-flags" "--project=. -e 'using Pkg; Pkg.instantiate(); Pkg.add(\"Pluto\")'"];
                        };
                      };
                      pluto = let
                        runPluto = ''
                          import Pkg; import TOML; Pkg.instantiate();
                          if !isfile("Project.toml") || !haskey(TOML.parsefile(Base.active_project())["deps"], "Pluto")
                            Pkg.add("Pluto");
                          end
                          import Pluto; Pluto.run();
                        '';
                      in {
                        enable = config.enabledLanguages.julia;
                        path = {
                          value = "${pkgs.julia-bin}/bin/julia";
                          args = ["--add-flags" "--project=. -e '${runPluto}'"];
                        };
                      };
                      r = {
                        enable = config.enabledLanguages.r;
                        path = {
                          value = "${pkgs.rWrapper}/bin/R";
                          args = ["--add-flags" "--no-save --no-restore"];
                        };
                      };
                      initPython = {
                        enable = config.enabledLanguages.python;
                        path.value = "${pkgs.initPython}/bin/initPython";
                      };
                      initProject = {
                        enable = true;
                        path = {
                          value = "${pkgs.initProject}/bin/initProject";
                        };
                      };
                      updateDeps = {
                        enable = true;
                        path = {
                          value = "${pkgs.updateDeps}/bin/updateDeps";
                        };
                      };
                      node.enable = true;
                      perl.enable = true;
                      ruby.enable = true;
                    };
                  };
                  categories = {
                    julia = config.enabledLanguages.julia;
                    python = config.enabledLanguages.python;
                    r = config.enabledLanguages.r;
                    project = true;
                    gitPlugins = config.enabledPackages.gitPlugins;
                    background = config.theme.background;
                    colorscheme = config.theme.colorscheme;
                  };
                }
              );
            };
        });
      in
        utils.mkAllWithDefault finalPackage
    );
  in {
    packages = projectConfig;
    devShells = forSystems (system: let
      pkgs = import nixpkgs {inherit system;};
    in {
      default = let
        shellCmds = pkgs.lib.concatLines (pkgs.lib.filter (cmd: cmd != "") [
          (pkgs.lib.optionalString config.enabledLanguages.r "  - ${config.defaultPackageName}-r: Launch R console")
          (pkgs.lib.optionalString config.enabledLanguages.julia "  - ${config.defaultPackageName}-jl: Launch Julia REPL")
          (pkgs.lib.optionalString config.enabledLanguages.julia "  - ${config.defaultPackageName}-pluto: Launch Pluto.jl notebook")
          (pkgs.lib.optionalString config.enabledLanguages.julia "  - ${config.defaultPackageName}-initJl: Init existing Julia project")
          (pkgs.lib.optionalString config.enabledLanguages.python "  - ${config.defaultPackageName}-marimo: Launch Marimo notebook")
          (pkgs.lib.optionalString config.enabledLanguages.python "  - ${config.defaultPackageName}-py: Launch IPython REPL")
          (pkgs.lib.optionalString config.enabledLanguages.python "  - ${config.defaultPackageName}-initPython: Init python project")
          " "
          "To adjust options run: ${config.defaultPackageName} flake.nix"
        ]);
      in
        pkgs.mkShell {
          name = config.defaultPackageName;
          packages = [projectConfig.${system}.default];
          inputsFrom = [];
          shellHook = ''
            echo ""
            echo "=========================================================================="
            echo "🎯  ${config.defaultPackageName} Development Environment"
            echo "---"
            echo "📝  Run '${config.defaultPackageName}-initProject' to set up project structure"
            echo "🔄  Run '${config.defaultPackageName}-updateDeps' to update all dependencies"
            echo "---"
            echo "🚀  Available commands:"
            echo "  - ${config.defaultPackageName}: Launch Neovim"
            echo "  - ${config.defaultPackageName}-g: Launch Neovide"
            echo "${shellCmds}"
            echo "=========================================================================="
            echo ""
          '';
        };
    });
  };
  inputs = {
    rixpkgs.url = "https://github.com/rstats-on-nix/nixpkgs/archive/2025-08-11.tar.gz";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats = {
      url = "github:dwinkler1/nixCatsConfig";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rixpkgs.follows = "rixpkgs";
        plugins-cmp-pandoc-references.follows = "plugins-cmp-pandoc-references";
        plugins-cmp-r.follows = "plugins-cmp-r";
        plugins-r.follows = "plugins-r";
      };
    };
    ## Git Plugins
    "plugins-r" = {
      url = "github:R-nvim/R.nvim";
      flake = false;
    };
    "plugins-cmp-r" = {
      url = "github:R-nvim/cmp-r";
      flake = false;
    };
    "plugins-cmp-pandoc-references" = {
      url = "github:jmbuhr/cmp-pandoc-references";
      flake = false;
    };
  };
  nixConfig = {
    extra-substituters = [
      "https://rstats-on-nix.cachix.org"
      "https://rde.cachix.org"
    ];
    extra-trusted-public-keys = [
      "rstats-on-nix.cachix.org-1:vdiiVgocg6WeJrODIqdprZRUrhi1JzhBnXv7aWI6+F0="
      "rde.cachix.org-1:yRxQYM+69N/dVER6HNWRjsjytZnJVXLS/+t/LI9d1D4="
    ];
  };
}
