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

  programs.fuse.userAllowOther = true;

  # https://nixos.wiki/wiki/Docker
  virtualisation.docker.enable = true;
  virtualisation.docker.daemon.settings = {
    data-root = "/scratch/docker-sm";
  };

  # nvidia docker
  # systemd.services.containerd.path = with pkgs; [
  #   containerd
  #   nvidia-container-toolkit
  # ];
  hardware.nvidia-container-toolkit.enable = true;

  dots = {
    modules = {
      user.home = ./home.nix;
      user.name = "yineichen";
    };
    profiles = {
      desktop = {
        enable = true;
        wm = "dwm";
      };
    };
  };
}
