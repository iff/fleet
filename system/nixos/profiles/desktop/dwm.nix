{
  config,
  lib,
  pkgs,
  inputs,
  user,
  ...
}:

with lib;
let
  cfg = config.dots.profiles.desktop;

  dwm-ltstatus = pkgs.writeScriptBin "dwm-ltstatus" ''
    #! /usr/bin/env -S ltstatus run

    import os
    import re
    import subprocess
    import threading
    import time
    from pathlib import Path

    import ltstatus.monitor as m

    sound_aliases = {
        "iFi (by AMR) HD USB Audio Pro": "ifi",
        "apm.zero": "apm",
        "Dummy Output": "none",
    }

    event = threading.Event()
    with (
        m.spotify(event) as spotify,
        m.process_alerts(flags={"steam": re.compile(r".*steam.*")}) as alerts,
        m.redshift(event) as redshift,
        m.datetime() as datetime,
        m.cpu() as cpu,
        m.nvidia() as nvidia,
        m.diskpie() as diskpie,
    ):
        while True:
            event.wait(1)
            event.clear()
            segments = [
                spotify(),
                alerts(),
                f"󰬊 {cpu()}󰯾 {nvidia()}{diskpie()}",
                redshift(),
                datetime(),
            ]
            segments = [s for s in segments if s != ""]
            subprocess.run(
                  args=[
                        "xsetroot",
                        "-name",
                        " " + " | ".join(segments) + " ",
                 ],
                 check=True,
            )
  '';
in
{
  config = mkIf (cfg.enable && builtins.elem "dwm" cfg.wm) {
    environment.systemPackages = with pkgs; [
      inotify-tools
      xinit
    ];

    services.xserver = {
      windowManager.dwm = {
        enable = true;
        package = pkgs.dwm.overrideAttrs {
          src = builtins.getAttr "iff-dwm" inputs;
        };
      };
      displayManager.startx.enable = true;
      enableTearFree = true;
      upscaleDefaultCursor = true;
      dpi = 220;
      screenSection = ''
        Option "metamodes" "5120x2880_120 +0+0"
      '';
    };

    programs.slock.enable = true;

    location = {
      provider = "manual";
      latitude = 47.4;
      longitude = 8.5;
    };

    services = {
      redshift = {
        enable = true;
        temperature = {
          day = 5700;
          night = 3200;
        };
        brightness = {
          day = "1.0";
          night = "0.7";
        };
        extraOptions = [
          "-m"
          "randr"
          "-t"
          "1"
        ];
      };
    };

    home-manager.users.${user} = {
      home.packages = [
        pkgs.dmenu-rs
        pkgs.feh
        pkgs.gthumb
        pkgs.scrot
        inputs.ltstatus.packages.${pkgs.stdenv.hostPlatform.system}.default
        dwm-ltstatus
      ];

      home.file.".xinitrc".text = ''
        #!/usr/bin/env zsh
        set -eux -o pipefail

        # monitor never off
        xset -dpms
        xset s off
        setterm --blank 0 --powerdown 0

        # TODO
        # GDK_SCALE=2
        # GDK_DPI_SCALE=2
        # QT_AUTO_SCREEN_SET_FACTOR=0
        # QT_SCALE_FACTOR=2
        # QT_FONT_DPI=220

        feh --bg-scale ${./backgrounds/fluffy_galaxies.png}
        redshift -r -v & # |& ts '%F %T' >& $HOME/.log-redshift &

        dwm-ltstatus >& .log-dwm-status &

        dwm

        kill %ltstatus || true
      '';
    };
  };
}
