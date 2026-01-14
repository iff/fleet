{ user, self, ... }:

{
  imports = [ ./hardware.nix ];

  services.openssh = {
    ports = [ 3438 ];
    settings = {
      # AllowUsers = [ "xxx" ];
      X11Forwarding = false;
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

  home-manager.users."${user}" = self.lib.mkUserHome { config = ./home.nix; };

  dots = {
    profiles = {
      desktop = {
        enable = true;
        wm = "hyprland";
      };
    };
  };
}
