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
      pkgs.swaylock-effects # see https://github.com/jirutka/swaylock-effects
    ];

    services.wlsunset = {
      enable = true;
      latitude = "47.4";
      longitude = "8.5";
      temperature = {
        day = 5700;
        night = 3200;
      };
    };

    nixpkgs.overlays = [
      (final: prev: {
        waybar = prev.waybar.overrideAttrs (oldAttrs: {
          mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
        });
      })
    ];

    programs.waybar = {
      enable = true;
      # systemd = {
      #   enable = false;
      #   target = "graphical-session.target";
      # };
    };

    xdg.configFile = {
      "swaylock/config".source = hypr/swaylock.config;
      "waybar/config.jsonc".source = hypr/waybar.jsonc;
      "waybar/style.css".source = hypr/waybar.css;
      "hypr/hyprland.conf".source = hypr/hyprland.conf;
      "hypr/hyprpaper.conf".text = ''
        preload = ${./mountains.jpg}
        wallpaper = ,${./mountains.jpg} 
      '';
    };
  };
}
