{
  config,
  lib,
  pkgs,
  user,
  ...
}:

with lib;
let
  cfg = config.dots.profiles.desktop;

  wmList = [
    "dwm"
    "niri"
    "hyprland"
    "all"
  ];
in
{
  imports = [
    ./dwm.nix
    ./hyprland.nix
    ./niri.nix
    ./wlsunset.nix
    ./wayland-overrides.nix
  ];

  options.dots.profiles.desktop = {
    enable = mkEnableOption "desktop profile";
    wm = mkOption {
      description = "window manager";
      type = types.enum (wmList);
      default = "hyprland";
    };
    enableWaylandOverrides = mkOption {
      description = "Enable wayland-specific package overrides (e.g., ozone flags for Chrome)";
      type = types.bool;
      default = false;
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

    # NOTE currently no bluetooth devices
    # hardware.bluetooth.enable = true;
    # services.blueman.enable = true;

    environment.systemPackages = with pkgs; [
      pamixer
      pulsemixer
    ];

    # fonts.fontconfig = mkIf (cfg.wm == "hyprland" || cfg.wm == "niri") {
    #   antialias = true;
    #
    #   # fixes antialiasing blur
    #   hinting = {
    #     enable = true;
    #     # style = "slight"; # no difference
    #     # autohint = true; # no difference
    #   };
    #
    #   subpixel = {
    #     rgba = "rgb";
    #     lcdfilter = "default";
    #   };
    # };

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = false;

      open = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      nvidiaSettings = true;
    };

    # TODO seems to be needed for wayland to get nvidia drivers?
    services.xserver = {
      enable = true;
      # load nvidia driver for Xorg and Wayland (under xserver)
      videoDrivers = [ "nvidia" ];
      xkb.layout = "us";
      displayManager.xserverArgs = [
        "-nolisten tcp" # enableTCP = false;
        "-ardelay 200" # autoRepeatDelay = 200;
        "-arinterval 20" # autoRepeatInterval = 20;
      ];
    };
  };
}
