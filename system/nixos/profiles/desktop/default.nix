{ config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.dots.profiles.desktop;

  wmList = [ "dwm" "sway" "hyprland" ];
in
{
  options.dots.profiles.desktop = {
    enable = mkEnableOption "desktop profile";
    wm = mkOption {
      description = "window manager";
      type = types.enum (wmList);
      default = "hyprland";
    };
  };

  config = mkIf cfg.enable {
    # hardware = {
    #   pulseaudio = {
    #     enable = true;
    #     support32Bit = true;
    #     package = pkgs.pulseaudioFull;
    #   };
    # };

    services.getty = {
      # autologinOnce = true;
      # autologinUser = lib.mkDefault "dkuettel"; # TODO for iso install
      extraArgs = [ "--skip-login" ];
      # TODO a way to never ever ask for user? or at least not echo when typing?
      loginOptions = config.dots.modules.user.name;
      # TODO if i ever run remotely, how to keep the monitor off?
    };

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    services.dbus.enable = true;
    services.dbus.packages = [ pkgs.gcr ];

    # hardware.bluetooth.enable = true;
    # services.blueman.enable = true;

    environment.systemPackages = with pkgs; [
      pamixer
      pulsemixer
    ] ++ lib.optionals (cfg.wm == "sway" || cfg.wm == "hyprland") [
      xdg-utils
      glib
      dracula-theme
      adwaita-icon-theme
      mako
      wl-clipboard
      wlr-randr
      wayland
      wayland-scanner
      wayland-utils
      # egl-wayland
      wayland-protocols
    ] ++ lib.optionals (cfg.wm == "hyprland") [
      inputs.hypr-contrib.packages.${pkgs.system}.grimblast
      hyprpaper
      rofi-wayland
    ] ++ lib.optionals (cfg.wm == "dwm") [
      xorg.xinit
    ];

    fonts.fontconfig = mkIf (cfg.wm == "hyprland") {
      antialias = true;

      # fixes antialiasing blur
      hinting = {
        enable = true;
        # style = "slight"; # no difference
        # autohint = true; # no difference
      };

      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };
    };

    hardware.graphics = {
      enable = true;
    };

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = false;

      open = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    # TODO also neede for sway but actually super instable at the moment
    # services.xserver.videoDrivers = [ "nvidia" ];

    # xorg and dwm

    services.xserver = mkIf (cfg.wm == "dwm" || cfg.wm == "hyprland") {
      enable = true;
      xkb.layout = "us";
      videoDrivers = [ "nvidia" ];
      # no display manager (https://nixos.wiki/wiki/Using_X_without_a_Display_Manager)
      displayManager.startx.enable = true;
      # currently only for DWM
      windowManager.dwm.enable = true;
      windowManager.dwm.package = pkgs.dwm.overrideAttrs {
        src = builtins.getAttr "iff-dwm" inputs;
      };
    };

    programs.slock.enable = mkIf (cfg.wm == "dwm") true;

    # wayland and sway setup below

    programs.xwayland.enable = mkIf (cfg.wm == "sway" || cfg.wm == "hyprland") true;

    programs.hyprland = mkIf (cfg.wm == "hyprland") {
      enable = true;
      xwayland.enable = true;
    };

    programs.sway = mkIf (cfg.wm == "sway") {
      enable = true;
      wrapperFeatures.gtk = true;
    };

    # FIXME only for homemananger sway
    # security.polkit = mkIf (cfg.wm == "sway") {
    #   enable = true;
    # };

    xdg.portal = mkIf (cfg.wm == "sway" || cfg.wm == "hyprland") {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      # gtkUsePortal = true;
    };

    security.pam.services = mkIf (cfg.wm == "sway" || cfg.wm == "hyprland") {
      swaylock = { };
    };

    programs.swaylock = mkIf (cfg.wm == "sway" || cfg.wm == "hyprland") {
      enable = true;
      settings = {
        screenshots = true;
        clock = true;
        indicator = true;
        indicator-radius = 100;
        indicator-thickness = 7;
        effect-blur = "7x5";
        effect-vignette = "0.5:0.5";
        color = "00000000";
        ring-color = "3b4252";
        key-hl-color = "880033";
        line-color = "00000000";
        inside-color = "00000088";
        separator-color = "00000000";
        # grace = 2;
      };
    };

    # Hyprland hack
    # commit before removing things
    # Gedit 09540e9127dfa06eda722473300bb4c1708b8528:system/nixos/profiles/desktop/hyprland.nix
    # missing: swaylock (additional features?), wlsunset

    nixpkgs.overlays = [
      (final: prev: {
        waybar = prev.waybar.overrideAttrs (oldAttrs: {
          mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
        });
      })
    ];

    programs.waybar = mkIf (cfg.wm == "hyprland") {
      enable = true;
      # systemd = {
      #   enable = false;
      #   target = "graphical-session.target";
      # };
    };

    xdg.configFile = mkIf (cfg.wm == "hyprland") {
      "waybar/config.jsonc".source = hypr/waybar.jsonc;
      "waybar/style.css".source = hypr/waybar.css;
      "hypr/hyprland.conf".source = hypr/hyprland.conf;
      "hypr/hyprpaper.conf".text = ''
        preload = ${../../../../home/profiles/mountains.jpg}
        wallpaper = ,${../../../../home/profiles/mountains.jpg} 
      '';
    };
  };
}
