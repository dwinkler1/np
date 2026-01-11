# R packages overlay
final: prev: let
  reqPkgs = with final.rpkgs.rPackages;
    [
      broom
      data_table
      janitor
      languageserver
      reprex
      styler
      tidyverse
    ]
    ++ (with final.extraRPackages; [
      httpgd
    ])
    ++ (prev.lib.optional (builtins.pathExists ./r-packages.nix) (import ./r-packages.nix final.rpkgs));
in {
  quarto = final.rpkgs.quarto.override {extraRPackages = reqPkgs;};
  rWrapper = final.rpkgs.rWrapper.override {packages = reqPkgs;};
}
