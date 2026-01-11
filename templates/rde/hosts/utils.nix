# Utility and common host configurations
config: pkgs: {
  g = {
    enable = true;
    path = {
      value = "${pkgs.neovide}/bin/neovide";
      args = [
        "--add-flags"
        "--neovim-bin ${config.defaultPackageName}"
      ];
    };
  };

  initProject = {
    enable = true;
    path = {
      value = "${pkgs.initProject}/bin/initProject";
    };
  };

  initDevenv = {
    enable = config.enabledPackages.devenv;
    path = {
      value = "${pkgs.devenv}/bin/devenv";
      args = ["--add-flags" "init"];
    };
  };

  activateDevenv = {
    enable = config.enabledPackages.devenv;
    path = {
      value = "${pkgs.activateDevenv}/bin/activateDevenv";
    };
  };

  devenv = {
    enable = config.enabledPackages.devenv;
    path = {
      value = "${pkgs.devenv}/bin/devenv";
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
}
