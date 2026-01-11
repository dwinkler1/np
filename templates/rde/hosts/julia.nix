# Julia-related host configurations
#
# This module defines all Julia-related commands available in the dev shell.
# Julia is configured with project-local package management.
#
# Available commands (when Julia is enabled):
#   - <name>-jl: Launch Julia REPL with project environment
#   - <name>-pluto: Launch Pluto.jl notebook server
#   - <name>-initJl: Initialize Julia project and install Pluto
#
# How it works:
#   - All commands use --project=. to activate local Project.toml
#   - JULIA_NUM_THREADS=auto enables multi-threading
#   - Packages are managed via Julia's built-in Pkg manager
#
# Project setup:
#   1. Run <name>-initJl to create Project.toml
#   2. Add packages: julia --project=. -e 'using Pkg; Pkg.add("PackageName")'
#   3. Packages are stored in Project.toml and Manifest.toml
#
# Dependencies: julia-bin (configured in flake.nix)
config: pkgs: {
  # jl: Julia REPL with project environment
  # Activates local Project.toml for package management
  # Use Pkg.add("PackageName") to install packages
  jl = {
    enable = config.enabledLanguages.julia;
    path = {
      value = "${pkgs.julia-bin}/bin/julia";
      args = ["--add-flags" "--project=."];
    };
  };

  # initJl: Initialize Julia project
  # Creates Project.toml and installs Pluto.jl notebook
  # Run this once to set up Julia package management
  initJl = {
    enable = config.enabledLanguages.julia;
    path = {
      value = "${pkgs.julia-bin}/bin/julia";
      args = ["--add-flags" "--project=. -e 'using Pkg; Pkg.instantiate(); Pkg.add(\"Pluto\")'"];
    };
  };

  # pluto: Launch Pluto.jl interactive notebook
  # Auto-installs Pluto if not present in Project.toml
  # Opens browser with notebook interface
  # Notebooks are reactive - cells update automatically
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
}
