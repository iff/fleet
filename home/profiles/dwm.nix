{ config, lib, pkgs, inputs, ... }:

with lib;
let
  dwm-ltstatus = pkgs.writeScriptBin "dwm-ltstatus"
    ''
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
      ):
          while True:
              event.wait(1)
              event.clear()
              segments = [
                  spotify(),
                  alerts(),
                  f"󰬊 {cpu()}󰯾 {nvidia()}",
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

  cfg = config.dots.profiles.dwm;
in
{
  options.dots.profiles.dwm = {
    enable = mkEnableOption "dwm profile";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.dmenu-rs
      pkgs.feh
      pkgs.gthumb
      pkgs.scrot
      inputs.ltstatus.packages.${pkgs.stdenv.hostPlatform.system}.app
      dwm-ltstatus
    ];

    home.file.".xinitrc".text = ''
      #!/usr/bin/env zsh
      set -eux -o pipefail

      # monitor never off
      xset -dpms
      xset s off
      setterm --blank 0 --powerdown 0

      feh --bg-scale ${./moon.jpg}
      redshift -r -v & # |& ts '%F %T' >& $HOME/.log-redshift &

      dwm-ltstatus >& .log-dwm-status &

      dwm

      kill %ltstatus || true
    '';
  };
}
