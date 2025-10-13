{ config, lib, pkgs, inputs, user, ... }:

with lib;
let
  cfg = config.dots.profiles.desktop;

  wmList = [ "dwm" "niri" "hyprland" ];
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
      loginOptions = user;
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
    ] ++ lib.optionals (cfg.wm == "niri" || cfg.wm == "hyprland") [
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
      egl-wayland
      wayland-protocols
      #
      inputs.hypr-contrib.packages.${pkgs.system}.grimblast
      hyprpaper
      rofi
    ] ++ lib.optionals (cfg.wm == "dwm") [
      xorg.xinit
    ];

    # does not seem to help with fuzzy font in browser
    fonts.fontconfig = mkIf (cfg.wm == "hyprland" || cfg.wm == "niri") {
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
      nvidiaSettings = true;
    };

    services.xserver = {
      # load nvidia driver for Xorg and Wayland (under xserver)
      videoDrivers = [ "nvidia" ];
    } // mkIf (cfg.wm == "dwm") {
      enable = true;
      xkb.layout = "us";
      # no display manager (https://nixos.wiki/wiki/Using_X_without_a_Display_Manager)
      displayManager.startx.enable = true;
      windowManager.dwm = {
        enable = true;
        package = pkgs.dwm.overrideAttrs {
          src = builtins.getAttr "iff-dwm" inputs;
        };
      };
    };

    programs.slock.enable = mkIf (cfg.wm == "dwm") true;

    # wayland and sway setup below

    environment.sessionVariables = mkIf (cfg.wm == "niri" || cfg.wm == "hyprland") {
      NIXOS_OZONE_WL = "1";
    };

    programs.xwayland.enable = mkIf (cfg.wm == "hyprland") true;

    programs.hyprland = mkIf (cfg.wm == "hyprland") {
      enable = true;
      xwayland.enable = true;
    };

    # TODO should be niri - for testing
    programs.niri = mkIf (cfg.wm == "hyprland") {
      enable = true;
    };
    # niri pulls gnome
    services.gnome.gcr-ssh-agent.enable = false;

    xdg.portal = mkIf (cfg.wm == "niri" || cfg.wm == "hyprland") {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      # gtkUsePortal = true;
    };

    security.pam.services = mkIf (cfg.wm == "niri" || cfg.wm == "hyprland") {
      swaylock = { };
    };
  };
}
