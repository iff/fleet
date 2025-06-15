{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.dots.profiles.hyprland;
in
{
  options.dots.profiles.hyprland = {
    enable = mkEnableOption "hyprland profile";
  };

  config = mkIf cfg.enable {
    home.packages = [
    ];

    programs.swaylock = {
      enable = true;
      settings = {
        screenshots = true;
        clock = true;
        indicator = true;
        indicator-radius = 100;
        indicator-thickness = 7;
        effect-blur = "7x5";
        effect-vignette = "0.5:0.5";
        color = "00000000";
        ring-color = "3b4252";
        key-hl-color = "880033";
        line-color = "00000000";
        inside-color = "00000088";
        separator-color = "00000000";
        # grace = 2;
      };
    };

    xdg.configFile = {
      "waybar/config.jsonc".source = ../../system/nixos/profiles/desktop/hypr/waybar.jsonc;
      "waybar/style.css".source = ../../system/nixos/profiles/desktop/hypr/waybar.css;
      "hypr/hyprland.conf".source = ../../system/nixos/profiles/desktop/hypr/hyprland.conf;
      "hypr/hyprpaper.conf".text = ''
        preload = ${./mountains.jpg}
        wallpaper = ,${./mountains.jpg} 
      '';
    };
  };
}
