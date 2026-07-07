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
  imports = [
    ./wayland.nix
  ];

  config = mkIf (cfg.enable && builtins.elem "river" cfg.wm) {
    environment.systemPackages = [
      pkgs.river
      pkgs.kanshi
    ];

    # mirrors what the (river-classic-targeted) programs.river-classic NixOS
    # module sets; portal backend selection is generic wlroots handling and
    # still applies here
    xdg.portal.config.river.default = [
      "wlr"
      "gtk"
    ];

    home-manager.users.${user} = {
      xdg.configFile = {
        "river/init" = {
          executable = true;
          text = ''
            #!/bin/sh
            # kanshi for output mode-setting
            ${lib.getExe pkgs.kanshi} &

            # spawn directly rather than relying on waybar's systemd unit being
            # WantedBy=graphical-session.target, which is unreliable here
            ${lib.getExe pkgs.waybar} &

            # river does not import its environment into systemd/dbus or start any session target itself.
            # kept for portals/screen-sharing, but --no-block so it can never stall startup
            export XDG_CURRENT_DESKTOP=river
            export XDG_SESSION_TYPE=wayland
            systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE
            dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE
            systemctl --user start --no-block graphical-session.target

            # ${lib.getExe pkgs.swaybg} -m fill -i ${./backgrounds/fluffy_galaxies.png} &
            exec /home/iff/src/ywm/target/debug/ywm
          '';
        };

        "kanshi/config".text = ''
          profile default {
              output "ASUSTek COMPUTER INC XG27JCG TBLMQS039011" mode 5120x2880@120Hz scale 2.0 position 0,0
          }
        '';
      };
    };
  };
}
