{ pkgs, user, lib, self, ... }:

{
  imports = [ ./hardware.nix ];

  # TODO causing issues with DHCP often restarting loosing connection
  # networking.interfaces.enp0s31f6.useDHCP = true;

  programs.steam.enable = true;
  programs.steam.protontricks.enable = true;

  services.tailscale.enable = true;

  services.dbus.implementation = "broker";

  virtualisation.docker.storageDriver = "btrfs";

  # show nvd diff after activation
  system.activationScripts.report-changes = ''
    PATH=$PATH:${lib.makeBinPath [ pkgs.nvd pkgs.nix ]}
    nvd diff $(find /nix/var/nix/profiles -name "system-*-link" -type l | sort -V | tail -2) || echo "No previous nixos generation found"
  '';

  home-manager.users."${user}" = self.lib.mkUserHome { config = ./home.nix; };

  dots = {
    profiles = {
      desktop = {
        enable = true;
        wm = "dwm";
      };
    };
  };
}
