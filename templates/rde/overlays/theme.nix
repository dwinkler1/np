# Extra theme packages overlay
#
# This overlay configures the Neovim color scheme based on user configuration.
# It transforms the theme config from flake.nix into a Neovim plugin structure.
#
# Usage:
#   - Configure theme in flake.nix config.theme section
#   - Specify colorscheme name, background (dark/light)
#   - Add custom Lua configuration in extraColorschemePackage
#
# The overlay exports:
#   - extraTheme: Plugin structure with theme configuration
#
# Built-in themes: cyberdream, onedark, tokyonight, kanagawa
config: final: prev: let
  # Transform user theme config into Neovim plugin format
  extraTheme = {
    # Get the plugin package from nixpkgs
    plugin = prev.vimPlugins."${config.theme.extraColorschemePackage.plugin}";
    # Theme name for identification
    name = config.theme.extraColorschemePackage.name;
    # Lua configuration to run when theme loads
    config = {
      lua = config.theme.extraColorschemePackage.extraLua;
    };
  };
in {
  # Export theme for use in Neovim configuration
  inherit extraTheme;
}
