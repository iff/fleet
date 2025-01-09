{ config, inputs, lib, pkgs, user, ... }:

{
  config = {
    time.timeZone = "Europe/Zurich";
    i18n.defaultLocale = "en_US.UTF-8";
    networking.networkmanager.enable = true;

    environment.systemPackages = with pkgs; [
      curl
      git
      jq
      lnav
      pciutils
      tree
      vim
    ];

    hardware.keyboard.zsa.enable = true;

    services = {
      cron.enable = true;
      openssh.enable = true;
    };

    virtualisation.docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };

    users.users.${config.dots.modules.user.name} = {
      isNormalUser = true;
      extraGroups = [ "wheel" "systemd-journal" "audio" "video" "input" "networkmanager" ];
      shell = pkgs.zsh;
      packages = with pkgs; [
      ];
    };

    # TODO move
    programs.zsh.enable = true;

    # some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    programs.mtr.enable = true;
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    security.sudo = {
      enable = true;
      extraRules = [{
        commands = [
          {
            command = "${pkgs.systemd}/bin/reboot";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.systemd}/bin/poweroff";
            options = [ "NOPASSWD" ];
          }
        ];
        groups = [ "wheel" ];
      }];
    };

    nix = {
      settings = {
        auto-optimise-store = true;
      };

      extraOptions = ''
        experimental-features = nix-command flakes
      '';

      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
    };
  };
}

