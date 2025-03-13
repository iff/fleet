{ ... }:

{
  imports = [ ./hardware.nix ];

  # TODO causing issues with DHCP often restarting loosing connection
  # networking.interfaces.enp0s31f6.useDHCP = true;

  services.tailscale.enable = true;

  services.dbus.implementation = "broker";

  virtualisation.docker.storageDriver = "btrfs";

  dots = {
    modules = {
      user.home = ./home.nix;
      user.name = "iff";
    };
    profiles = {
      desktop = {
        enable = true;
        wm = "dwm";
      };
    };
  };
}
