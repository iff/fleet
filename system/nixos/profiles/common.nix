{ config, inputs, lib, pkgs, user, ... }:

{
  config = {
    time.timeZone = "Europe/Zurich";
    i18n.defaultLocale = "en_US.UTF-8";
    networking.networkmanager.enable = true;

    services.syncthing = {
      enable = true;
      group = "users";
      user = config.dots.modules.user.name;
      dataDir = "/home/${config.dots.modules.user.name}/sync";
      overrideFolders = true;
      overrideDevices = true;
      settings = {
        options.urAccepted = -1;
        devices = {
          kharbranth = { id = "FX6KDKI-UPZE5RA-KEL7OX7-WER52KY-6WVQ6CY-HNK3UX3-23W3CEK-3HWTMAY"; };
          # shadesmar = { id = ""; }; # TODO 
        };
        # folders = {
        #   work = {
        #     path = "~/sync/work";
        #     devices = [ "kharbranth" "shadesmar" ];
        #   };
        # };
      };
    };
    systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true";

    environment.systemPackages = with pkgs; [
      curl
      git
      jq
      lnav
      pciutils
      tree
      vim
    ];

    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      # Certain features, including CLI integration and system authentication support,
      # require enabling PolKit integration on some desktop environments (e.g. Plasma).
      # polkitPolicyOwners = [ "yourUsernameHere" ];
    };

    # seems not to work for zen
    # see https://nixos.wiki/wiki/1Password for more options (ssh agent)
    environment.etc = {
      "1password/custom_allowed_browsers" = {
        text = ''
          zen
        '';
        mode = "0755";
      };
    };

    hardware.keyboard.zsa.enable = true;

    services = {
      cron.enable = true;
      openssh.enable = true;
    };

    virtualisation.docker = {
      enable = true;
      # issues with nvidia
      # rootless = {
      #   enable = true;
      #   setSocketVariable = true;
      # };
    };

    users.mutableUsers = false;
    users.users.root.initialHashedPassword = "";
    users.users.${config.dots.modules.user.name} = {
      hashedPassword = "$y$j9T$zVsqwbdQAF3uPBPoAtvDw0$Jqj.F2ERf2ZdfWaFkmrv/2s5AppXeZ53RJ6xBxjvHM8";
      isNormalUser = true;
      extraGroups = [ "docker" "wheel" "systemd-journal" "audio" "video" "input" "networkmanager" ];
      shell = pkgs.zsh;
      packages = with pkgs; [ ];
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

