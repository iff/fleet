{ config, lib, pkgs, ... }:

with lib;
let
  wm = pkgs.writeScriptBin "wm"
    ''
      #!/usr/bin/env zsh
      set -eux -o pipefail
    
      exec Hyprland
    '';

  toggle-wlsunset = pkgs.writeScriptBin "toggle-wlsunset"
    ''
      #!/usr/bin/env zsh
      set -eux -o pipefail
      
      if systemctl --user is-active --quiet wlsunset.service; then
          systemctl --user stop wlsunset.service
      else
          systemctl --user start wlsunset.service
      fi
    '';

  wlsunset-status = pkgs.writeScriptBin "wlsunset-status"
    ''
      #!/usr/bin/env zsh
      set -eux -o pipefail
        
      if systemctl --user is-active --quiet wlsunset.service; then
          echo "on"
      else
          echo "off"
      fi
    '';

  cfg = config.dots.profiles.hyprland;
in
{
  options.dots.profiles.hyprland = {
    enable = mkEnableOption "hyprland profile";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.swaylock-effects # see https://github.com/jirutka/swaylock-effects
      wm
      wlsunset-status
      toggle-wlsunset
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


    programs.waybar = {
      enable = true;
      systemd = {
        enable = true;
        target = "graphical-session.target";
      };
    };

    xdg.configFile = {
      "swaylock/config".source = hypr/swaylock.config;
      "waybar/config.jsonc".source = hypr/waybar.jsonc;
      "waybar/style.css".source = hypr/waybar.css;
      "hypr/hyprland.conf".source = hypr/hyprland.conf;
      "hypr/hyprpaper.conf".text = ''
        preload = ${./moon.jpg}
        wallpaper = ,${./moon.jpg} 
      '';
    };
  };
}
