{ pkgs, ... }:

{
  home.packages = with pkgs; [
    _1password-gui
    awscli2
    cmake
    eigen
    geeqie
    google-chrome
    lnav
    spotify
    sshfs
    ssm-session-manager-plugin
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
