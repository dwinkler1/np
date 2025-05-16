final: prev: {
  rWrapper = prev.rWrapper.override {
    packages = with prev.rPackages; [
      languageserver
      fixest
      dplyr
      ggplot2
      janitor
      tidyr
      WeightIt
      broom
      (buildRPackage {
        name = "nvimcom";
        src = pkgs.fetchFromGitHub {
          owner = "R-nvim";
          repo = "R.nvim";
          rev = "f30c3b2be9ca1a3c277c5e66f5612774cc3fbcf4";
          sha256 = "sha256-X5ZfbrG7FtGJpnMJ2b7FMY/OM9rIIliFSqnbtudZCZg=";
        };
        sourceRoot = "source/nvimcom";
        buildInputs = with prev; [
          R
          gcc
          gnumake
        ];
        propagatedBuildInputs = [ ];
      })
    ];
  };
}
