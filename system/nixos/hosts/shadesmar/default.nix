{ pkgs, ... }:

{
  imports = [ ./hardware.nix ];

  services.openssh = {
    enable = true;
    ports = [ 3438 ];
    settings = {
      # AllowUsers = [ "xxx" ];
      X11Forwarding = false;
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # needed for sshfs
  programs.fuse.userAllowOther = true;

  virtualisation.docker.storageDriver = "zfs";

  # nvidia docker
  hardware.nvidia-container-toolkit.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  services.dbus.implementation = "broker";
  services.blueman.enable = true;

  dots = {
    modules = {
      user.home = ./home.nix;
      user.name = "yineichen";
    };
    profiles = {
      desktop = {
        enable = true;
        wm = "hyprland";
      };
    };
  };
}
