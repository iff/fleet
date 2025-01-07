{ pkgs, ... }:

{
  home.packages = with pkgs; [
    _1password-gui
    cmake
    geeqie
    google-chrome
    lnav
    spotify
    sshfs
    syncthing
    uv
    python310
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
