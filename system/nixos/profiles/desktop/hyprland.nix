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

  wm = pkgs.writeScriptBin "wm" ''
    #!/usr/bin/env zsh
    set -eux -o pipefail

    exec Hyprland
  '';
in
{
  imports = [
    ./wayland.nix
  ];

  config = mkIf (cfg.enable && (cfg.wm == "hyprland" || cfg.wm == "all")) {
    programs.xwayland.enable = true;

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    home-manager.users.${user} = {
      home.packages = [
        wm
      ];

      xdg.configFile = {
        "hypr/hyprland.conf".source = ./config/hyprland.conf;
      };
    };
  };
}
