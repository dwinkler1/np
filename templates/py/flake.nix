{
  description = "Project Template";
  inputs = {
    rixpkgs.url = "https://github.com/rstats-on-nix/nixpkgs/archive/2025-05-19.tar.gz";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nCats.url = "github:dwinkler1/nixCatsConfig";
    nCats.inputs.nixpkgs.follows = "nixpkgs";
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    self,
    nixpkgs,
    nCats,
    ...
  } @ inputs: let
    forSystems = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
  in {
    packages = forSystems (
      system: let
        inherit (nCats) utils;
        finalPackage = nCats.packages.${system}.default.override (prev: {
          dependencyOverlays =
            prev.dependencyOverlays
            ++ [
              (utils.standardPluginOverlay inputs)
              (final: prev: {
                rpkgs = inputs.rixpkgs.legacyPackages.${system};
              })
              (final: prev: let
                # Load a uv workspace from a workspace root.
                # Uv2nix treats all uv projects as workspace projects.
                workspace = uv2nix.lib.workspace.loadWorkspace {workspaceRoot = ./.;};

                # Create package overlay from workspace.
                overlay = workspace.mkPyprojectOverlay {
                  # Prefer prebuilt binary wheels as a package source.
                  # Sdists are less likely to "just work" because of the metadata missing from uv.lock.
                  # Binary wheels are more likely to, but may still require overrides for library dependencies.
                  sourcePreference = "wheel"; # or sourcePreference = "sdist";
                  # Optionally customise PEP 508 environment
                  # environ = {
                  #     platform_release = "5.10.65";
                  # };
                };

                # Extend generated overlay with build fixups
                #
                # Uv2nix can only work with what it has, and uv.lock is missing essential metadata to perform some builds.
                # This is an additional overlay implementing build fixups.
                # See:
                # - https://pyproject-nix.github.io/uv2nix/FAQ.html
                pyprojectOverrides = _final: _prev: {
                  # Implement build fixups here.
                  # Note that uv2nix is _not_ using Nixpkgs buildPythonPackage.
                  # It's using https://pyproject-nix.github.io/pyproject.nix/build.html
                };

                # Construct package set
                pythonSet =
                  # Use base package set from pyproject.nix builders
                  (pkgs.callPackage pyproject-nix.build.packages {inherit python;}).overrideScope
                  (
                    lib.composeManyExtensions [
                      pyproject-build-systems.overlays.default
                      overlay
                      pyprojectOverrides
                    ]
                  );
              in {
                venv = pythonSet.mkVirtualEnv builtins.toString ./. workspace.deps.default;
              })
              (import (builtins.path {
                path = ./rpkgs.nix;
                name = "my-rpackages";
              }))
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
            } @ packageDef: let
              myPy = pkgs.python313;
            in {
              lspsAndRuntimeDeps.rdev = with pkgs; [
                myPy
                uv
                nodejs
                ruff
                just
                wget
                python313Packages.python-lsp-server
              ];
              environmentVariables.rdev = {
                # Prevent uv from managing Python downloads
                UV_PYTHON_DOWNLOADS = "never";
                # Force uv to use nixpkgs Python interpreter
                UV_PYTHON = myPy.interpreter;
              };
            }
          );

          packageDefinitions =
            prev.packageDefinitions
            // {
              nixCats = utils.mergeCatDefs prev.packageDefinitions.nixCats (
                {...}: {
                  settings = {
                    suffix-path = false;
                    suffix-LD = false;
                  };
                  categories = {
                    rdev = true;
                  };
                }
              );
            };
        });
      in
        utils.mkAllWithDefault finalPackage
    );
  };
}
