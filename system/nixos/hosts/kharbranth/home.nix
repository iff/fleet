{ pkgs, ... }:

{
  home.packages = with pkgs; [
    geeqie
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
      dwm.enable = true;
      linux.enable = true;
    };
    alacritty = {
      enable = true;
      font_size = 14.0;
      font_normal = "ZedMono Nerd Font";
    };
    osh.enable = true;
    # syncthing.enable = true;
    zen.enable = true;
  };

  # Hyprland hack
  # commit before removing things
  # Gedit 09540e9127dfa06eda722473300bb4c1708b8528:system/nixos/profiles/desktop/hyprland.nix
  # missing: swaylock, wlsunset

  xdg.configFile."hypr/hyprland.conf".source = ../../profiles/desktop/hypr/hyprland.conf;
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    preload = ${../../../../home/profiles/mountains.jpg}
    wallpaper = ,${../../../../home/profiles/mountains.jpg} 
  '';

  programs.swaylock = {
    settings = {
      screenshots = true;
      clock = true;
      indicator = true;
      indicator-radius = 100;
      indicator-thickness = 7;
      effect-blur = "7x5";
      effect-vignette = "0.5:0.5";
      ring-color = "3b4252";
      key-hl-color = "880033";
      line-color = "00000000";
      inside-color = "00000088";
      separator-color = "00000000";
      # grace = 2;
    };
  };

  nixpkgs.overlays = [
    (final: prev: {
      waybar = prev.waybar.overrideAttrs (oldAttrs: {
        mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
      });
    })
  ];

  programs.waybar = {
    enable = true;
    # systemd = {
    #   enable = false;
    #   target = "graphical-session.target";
    # };
  };

  xdg.configFile."waybar/config.jsonc".source = ../../profiles/desktop/hypr/waybar.jsonc;
  xdg.configFile."waybar/style.css".source = ../../profiles/desktop/hypr/waybar.css;

}
