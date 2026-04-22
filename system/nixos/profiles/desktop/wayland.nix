{
  config,
  lib,
  pkgs,
  user,
  ...
}:

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
      grimblast
      hyprpaper
      # TODO anyrun hm config/file and plugins, fzf?
      anyrun
    ];

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common.default = [ "gtk" ];
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
          wallpaper {
              monitor =
              path = ${./backgrounds/fluffy_galaxies.png}
              fit_mode = cover
          }
        '';
      };
    };
  };
}
