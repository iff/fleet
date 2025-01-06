{ pkgs, ... }:

{
  home.packages = with pkgs; [
    _1password-gui
    geeqie
    google-chrome
    neovide
    protonmail-desktop
    roam-research
    spotify
    syncthing
    transmission_4-gtk
    vlc
  ];

  dots = {
    profiles = {
      dwm.enable = true;
      linux.enable = true;
    };
    alacritty = {
      enable = true;
      font_size = 12.0;
      font_normal = "ZedMono Nerd Font";
    };
    osh.enable = true;
    zen.enable = true;
  };
}
