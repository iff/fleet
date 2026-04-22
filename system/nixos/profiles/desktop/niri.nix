{
  config,
  lib,
  user,
  ...
}:

with lib;
let
  cfg = config.dots.profiles.desktop;
in
{
  imports = [
    ./wayland.nix
  ];

  config = mkIf (cfg.enable && builtins.elem "niri" cfg.wm) {
    programs.niri = {
      enable = true;
    };

    # niri pulls gnome
    services.gnome.gcr-ssh-agent.enable = false;

    home-manager.users.${user} = {
      xdg.configFile = {
        "niri/config.kdl".source = ./config/niri.kdl;
      };
    };
  };
}
