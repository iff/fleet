{ pkgs, user, lib, self, system, ... }:

{
  imports = [ ./hardware.nix ];

  # TODO causing issues with DHCP often restarting loosing connection
  # networking.interfaces.enp0s31f6.useDHCP = true;

  programs.steam.enable = true;
  programs.steam.protontricks.enable = true;

  services.tailscale.enable = true;

  services.dbus.implementation = "broker";

  virtualisation.docker.storageDriver = "btrfs";

  # show nvd diff afetr activation
  system.activationScripts.report-changes = ''
    PATH=$PATH:${lib.makeBinPath [ pkgs.nvd pkgs.nix ]}
    nvd diff $(ls -dv /nix/var/nix/profiles/system-*-link | tail -2)
  '';

  home-manager.users."${user}" = self.lib.mkUserHome { inherit system; config = ./home.nix; };

  dots = {
    profiles = {
      desktop = {
        enable = true;
        wm = "hyprland";
      };
    };
  };
}
