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

  toggle-wlsunset = pkgs.writeScriptBin "toggle-wlsunset" ''
    #!/usr/bin/env zsh
    set -eux -o pipefail

    if systemctl --user is-active --quiet wlsunset.service; then
        systemctl --user stop wlsunset.service
    else
        systemctl --user start wlsunset.service
    fi
  '';

  wlsunset-status = pkgs.writeScriptBin "wlsunset-status" ''
    #!/usr/bin/env zsh
    set -eux -o pipefail

    if systemctl --user is-active --quiet wlsunset.service; then
        echo "on"
    else
        echo "off"
    fi
  '';
in
{
  config = mkIf (cfg.enable && (cfg.wm == "hyprland" || cfg.wm == "niri" || cfg.wm == "all")) {
    home-manager.users.${user} = {
      home.packages = [
        toggle-wlsunset
        wlsunset-status
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
    };
  };
}
