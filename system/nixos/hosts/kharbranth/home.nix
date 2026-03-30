{ pkgs, ... }:

let
  switch = pkgs.writeScriptBin "switch" ''
    #!/usr/bin/env zsh
    set -eu -o pipefail

    nixos-rebuild switch --sudo --flake .
  '';

  widelands-2k = pkgs.writeScriptBin "widelands-2k" ''
    #!${pkgs.zsh}/bin/zsh
    set -eu -o pipefail
    xrandr --output DP-0 --mode 1920x1080 --rate 160
    function TRAPEXIT {
        xrandr --output DP-0 --mode 3840x2160 --rate 160
    }
    widelands --fullscreen
  '';
in
{
  home.packages = with pkgs; [
    geeqie
    ghostty
    google-chrome
    neovide
    perf
    protonmail-desktop
    # roam-research
    samply
    spotify
    transmission_4-gtk
    vlc
    slack
    zed-editor
    #
    switch
    #
    cudaPackages.cuda_nvcc
    cudaPackages.cudatoolkit
    # games
    beyond-all-reason
    widelands
    widelands-2k
  ];

  dots = {
    alacritty = {
      enable = true;
      decorations = "None";
      # for dwm, 14 for Hyprland/Niri
      font_size = 13.0;
      font_normal = "ZedMono Nerd Font";
    };
    # syncthing.enable = true;
    firefox.enable = true;
  };
}
