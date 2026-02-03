{
  pkgs,
  user,
  lib,
  self,
  ...
}:

{
  imports = [ ./hardware.nix ];

  # TODO causing issues with DHCP often restarting loosing connection
  # networking.interfaces.enp0s31f6.useDHCP = true;

  programs.steam.enable = true;
  programs.steam.protontricks.enable = true;

  services.tailscale.enable = true;

  # services.sshguard = {
  #   enable = true;
  #   whitelist = [
  #     "100.64.0.0/10" # tailscale
  #     "192.168.0.0/16" # local network
  #   ];
  #   attack_threshold = 20; # block after 2 failed attempts
  #   blocktime = 300;
  #   detection_time = 3600; # 1 hour detection window
  # };

  # services.ollama = {
  #   enable = true;
  #   acceleration = "cuda";
  # };

  services.dbus.implementation = "broker";

  virtualisation.docker.storageDriver = "btrfs";
  hardware.nvidia-container-toolkit.enable = true;

  # show dix diff after activation
  system.activationScripts.report-changes = ''
    PATH=$PATH:${
      lib.makeBinPath [
        pkgs.dix
        pkgs.nix
      ]
    }
    dix $(find /nix/var/nix/profiles -name "system-*-link" -type l | sort -V | tail -2) || echo "No previous nixos generation found"
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
