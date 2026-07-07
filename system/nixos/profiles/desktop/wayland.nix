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
  onNiri = builtins.elem "niri" cfg.wm;
in
{
  config = mkIf (
    cfg.enable && (builtins.elem "hyprland" cfg.wm || onNiri || builtins.elem "river" cfg.wm)
  ) {
    environment.systemPackages = with pkgs; [
      xdg-utils
      glib
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
          targets = ["graphical-session.target"];
        };

        settings.mainBar = {
          layer = "top";
          position = "top";

          margin-top = 3;
          margin-left = 3;
          margin-right = 3;

          modules-left = [ "tray" ];

          # window-title module differs per compositor; river has no
          # equivalent bar-facing protocol yet, so it gets nothing here
          modules-center = optional onNiri "niri/window";

          modules-right = [
            "cpu"
            "memory"
            "custom/nvidia"
            "network"
            "pulseaudio"
            "custom/wlsunset"
            "clock"
          ];

          "custom/nvidia" = {
            exec = "nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,nounits,noheader | sed 's/\\([0-9]\\+\\), \\([0-9]\\+\\)/\\1% \\2°C/g'";
            format = "{:10}";
            interval = 2;
          };

          "custom/wlsunset" = {
            exec = "wlsunset-status";
            format = "󰛨  {}";
            interval = 30;
            on-click = "toggle-wlsunset";
          };

          pulseaudio = {
            format = "  {volume:3}%";
            format-muted = "󰖁 Muted";
            tooltip = false;
          };

          clock = {
            interval = 1;
            format = "{:%H:%M}";
            tooltip-format = "{:%d.%m.%Y   Week %W}\n\n<tt><small>{calendar}</small></tt>";
            calendar = {
              mode = "month";
              mode-mon-col = 3;
              weeks-pos = "right";
              on-scroll = 1;
              format = {
                months = "<span color='#cba6f7'><b>{}</b></span>";
                days = "<span color='#cdd6f4'><b>{}</b></span>";
                weeks = "<span color='#94e2d5'> W{}</span>";
                weekdays = "<span color='#f9e2af'><b>{}</b></span>";
                today = "<span color='#f5e0dc'><b><u>{}</u></b></span>";
              };
            };
            on-click = "firefox https://calendar.proton.me";
          };

          memory = {
            interval = 1;
            format = "󰍛 {percentage:2}%";
            states.warning = 85;
          };

          cpu = {
            interval = 1;
            format = "󰻠 {usage:2}%";
          };

          network = {
            format-disconnected = "󱘖 ";
            format-ethernet = "󰈀 {bandwidthDownBits}";
            format-linked = "󰖪 {bandwidthDownBits}";
            tooltip = "{}";
            tooltip-format-wifi = "{ifname}\n{essid}\n{signalStrength}% \n{frequency} GHz\n󰇚 {bandwidthDownBits}\n󰕒 {bandwidthUpBits}";
            tooltip-format-ethernet = "{ifname}\n󰇚 {bandwidthDownBits} \n󰕒 {bandwidthUpBits}";
            interval = 10;
            min-length = 11;
          };

          tray = {
            icon-size = 13;
            spacing = 8;
          };
        };

        style = builtins.readFile ./config/waybar.css;
      };

      xdg.configFile = {
        "swaylock/config".source = ./config/swaylock.config;
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
