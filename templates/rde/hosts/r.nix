# R-related host configurations
config: pkgs: {
  r = {
    enable = config.enabledLanguages.r;
    path = {
      value = "${pkgs.rWrapper}/bin/R";
      args = ["--add-flags" "--no-save --no-restore"];
    };
  };
}
