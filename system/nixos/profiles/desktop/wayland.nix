{ config, lib, pkgs, inputs, user, ... }:

with lib;
let
  cfg = config.dots.profiles.desktop;
in
{
  config = mkIf (cfg.enable && (cfg.wm == "hyprland" || cfg.wm == "niri" || cfg.wm == "all")) {
    environment.systemPackages = with pkgs; [
      xdg-utils
      glib
      dracula-theme
      adwaita-icon-theme
      mako
      wl-clipboard
      wlr-randr
      wayland
      wayland-scanner
      wayland-utils
      egl-wayland
      wayland-protocols
      inputs.hypr-contrib.packages.${pkgs.stdenv.hostPlatform.system}.grimblast
      hyprpaper
      rofi
    ];

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    security.pam.services = {
      swaylock = { };
    };

    home-manager.users.${user} = {
      home.packages = [
        pkgs.swaylock-effects
      ];

      programs.waybar = {
        enable = true;
        systemd = {
          enable = true;
          target = "graphical-session.target";
        };
      };

      xdg.configFile = {
        "swaylock/config".source = ./config/swaylock.config;
        "waybar/config.jsonc".source = ./config/waybar.jsonc;
        "waybar/style.css".source = ./config/waybar.css;
        "hypr/hyprpaper.conf".text = ''
          preload = ${./backgrounds/moon.jpg}
          wallpaper = ,${./backgrounds/moon.jpg}
        '';
      };
    };
  };
}
