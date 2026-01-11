# Merges all host configurations from separate modules
config: pkgs: let
  pythonHosts = import ./python.nix config pkgs;
  juliaHosts = import ./julia.nix config pkgs;
  rHosts = import ./r.nix config pkgs;
  utilsHosts = import ./utils.nix config pkgs;
in
  pythonHosts // juliaHosts // rHosts // utilsHosts
