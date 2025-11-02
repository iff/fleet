{ pkgs, ... }:

let
  switch = pkgs.writeScriptBin "switch"
    ''
      #!/usr/bin/env zsh
      set -eu -o pipefail

      sudo nixos-rebuild switch --flake .
    '';
in
{
  home.packages = with pkgs; [
    geeqie
    google-chrome
    neovide
    perf
    protonmail-desktop
    roam-research
    samply
    spotify
    transmission_4-gtk
    vlc
    slack
    #
    switch
  ];

  dots = {
    profiles = {
      linux.enable = true;
    };
    alacritty = {
      enable = true;
      # for dwm, 14 for Hyprland/Niri
      font_size = 13.0;
      font_normal = "ZedMono Nerd Font";
    };
    # syncthing.enable = true;
    firefox.enable = true;
  };
}
