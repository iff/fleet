{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.dots.profiles.desktop;
in
{
  config = mkIf (cfg.enable && cfg.enableWaylandOverrides) {
    # Wayland-specific package overrides for better native support
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    nixpkgs.overlays = [
      (final: prev: {
        google-chrome = prev.google-chrome.override {
          commandLineArgs = "--enable-features=UseOzonePlatform --ozone-platform=wayland";
        };

        # TODO does not work yet
        # protonmail-desktop = prev.symlinkJoin {
        #   name = "protonmail-desktop";
        #   paths = [ prev.protonmail-desktop ];
        #   buildInputs = [ prev.makeWrapper ];
        #   postBuild = ''
        #     wrapProgram $out/bin/protonmail-desktop \
        #       --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland"
        #   '';
        # };
      })
    ];

    programs._1password-gui.package = lib.makeOverridable
      (args:
        pkgs.symlinkJoin {
          name = "1password-gui";
          paths = [ (pkgs._1password-gui.override args) ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/1password \
              --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland"
          '';
        }
      )
      { };
  };
}
