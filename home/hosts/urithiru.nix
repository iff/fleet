{ ... }:

{
  home.stateVersion = "24.05";

  dots = {
    profiles = {
      darwin.enable = true;
    };
    alacritty = {
      enable = true;
      font_size = 19.0;
      font_normal = "ZedMono Nerd Font";
    };
    firefox.enable = true;
    osh.enable = true;
    kanata.enable = true;
  };
}
