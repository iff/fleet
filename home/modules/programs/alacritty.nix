{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.dots.alacritty;
in
{
  options.dots.alacritty = {
    enable = mkEnableOption "enable alacritty";
    decorations = mkOption {
      description = "alacritty window decorations";
      type = types.str;
      default = "None";
    };
    font_size = mkOption {
      description = "alacritty font size";
      type = types.number;
    };
    font_normal = mkOption {
      description = "alacritty normal font";
      type = types.str;
      default = "Ubuntu Mono Nerd Font Complete Mono";
    };
    font_style = mkOption {
      description = "alacritty font weight/style (must match the font's style name, e.g. Regular, Medium, SemiBold, Bold)";
      type = types.str;
      default = "Regular";
    };
    theme = mkOption {
      description = "alacritty color theme, from pkgs.alacritty-theme's share/alacritty-theme/*.toml";
      type = types.enum (
        map (lib.removeSuffix ".toml") (
          builtins.attrNames (builtins.readDir "${pkgs.alacritty-theme}/share/alacritty-theme")
        )
      );
      default = "nordfox";
    };
  };

  config = mkIf cfg.enable {
    # FIXME alacritty and TMUX have issues with OSX native ncurses
    # see https://github.com/NixOS/nixpkgs/issues/204144
    home.packages = [ pkgs.alacritty-theme ] ++ lib.optionals pkgs.stdenv.isDarwin [ pkgs.ncurses ];

    programs.alacritty = {
      enable = cfg.enable;
      settings = lib.attrsets.recursiveUpdate (import ./alacritty/basics.nix) {
        general.import = [ "${pkgs.alacritty-theme}/share/alacritty-theme/${cfg.theme}.toml" ];
        font.normal.family = cfg.font_normal;
        font.normal.style = cfg.font_style;
        font.size = cfg.font_size;
        window.decorations = cfg.decorations;
      };
    };
  };
}
