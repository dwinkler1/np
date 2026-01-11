# Extra theme packages overlay
config: final: prev: let
  extraTheme = {
    plugin = prev.vimPlugins."${config.theme.extraColorschemePackage.plugin}";
    name = config.theme.extraColorschemePackage.name;
    config = {
      lua = config.theme.extraColorschemePackage.extraLua;
    };
  };
in {
  inherit extraTheme;
}
