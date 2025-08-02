{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # ‘libsoup-2.74.3’ is marked as insecure, refusing to evaluate
    # geeqie
    google-chrome
    neovide
    protonmail-desktop
    roam-research
    spotify
    transmission_4-gtk
    vlc
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
