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
    # ‘libsoup-2.74.3’ is marked as insecure, refusing to evaluate
    # geeqie
    google-chrome
    neovide
    nvd
    protonmail-desktop
    roam-research
    spotify
    transmission_4-gtk
    vlc
    #
    switch
  ];

  dots = {
    profiles = {
      hyprland.enable = true;
      linux.enable = true;
    };
    alacritty = {
      enable = true;
      font_size = 14.0;
      font_normal = "ZedMono Nerd Font";
    };
    osh.enable = true;
    # syncthing.enable = true;
    firefox.enable = true;
  };
}
