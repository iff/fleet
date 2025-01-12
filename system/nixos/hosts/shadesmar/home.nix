{ pkgs, ... }:

{
  home.packages = with pkgs; [
    geeqie
    syncthing
    # work
    awscli2
    ssm-session-manager-plugin
  ];

  services.blueman-applet.enable = true;

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
