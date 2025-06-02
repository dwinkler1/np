final: prev: let
  reqPkgs = with prev.rpkgs.rPackages; [
    Hmisc
    broom
    data_table
    dplyr
    ggplot2
    gt
    janitor
    psych
    tidyr
    quarto
    languageserver
    (buildRPackage {
      name = "nvimcom";
      src = prev.rpkgs.fetchFromGitHub {
        owner = "R-nvim";
        repo = "R.nvim";
        rev = "382858fcf23aabbf47ff06279baf69d52260b939";
        sha256 = "sha256-j2rXXO7246Nh8U6XyX43nNTbrire9ta9Ono9Yr+Eh9M=";
      };
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
  quarto = prev.rpkgs.quarto.override {extraRPackages = reqPkgs;};
  rWrapper = prev.rpkgs.rWrapper.override {packages = reqPkgs;};
  radianWrapper = prev.rpkgs.radianWrapper.override {packages = reqPkgs;};
}
