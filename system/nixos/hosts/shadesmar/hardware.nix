{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usb_storage"
        "usbhid"
        "sd_mod"
      ];
      kernelModules = [ "dm-snapshot" ];
    };

    # see https://openzfs.github.io/openzfs-docs/man/v2.3/4/zfs.4.html or man zfs 4
    # see https://wiki.nixos.org/wiki/ZFS
    # needed for reflink to work (pool also needs to have it enabled)
    # maybe also consider "zfs_bclone_wait_dirty"
    # TODO this works, but is it mergeable? using environment.etc."modprobe.d/zfs.conf".text didnt have an effect
    extraModprobeConfig = ''
      options zfs zfs_bclone_enabled=1
    '';

    loader = {
      timeout = 0; # TODO or null for wait, or 0 for on-key?
      systemd-boot = {
        enable = true;
        configurationLimit = 100;
        consoleMode = "0"; # all options often take long to appear
      };
      efi.canTouchEfiVariables = true;
    };
    # TODO does this add kernel modules? can i set options?
    supportedFilesystems = [ "zfs" ];
  };

  # needed for ZFS
  networking.hostId = "e163c59c";

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  fileSystems = {
    "/" = {
      device = "system/state";
      fsType = "zfs";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/2CDB-0C1A";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
      depends = [ "/" ];
    };
    "/nix" = {
      device = "system/nix";
      fsType = "zfs";
      depends = [ "/" ];
    };
    "/var/lib/docker" = {
      device = "system/docker";
      fsType = "zfs";
      depends = [ "/" ];
    };
  };

  fileSystems."/scratch" = {
    device = "/dev/disk/by-uuid/923aa534-f79d-43fa-8532-fc6a5f0cfd6a";
    fsType = "btrfs";
    options = [
      "noatime"
      "ssd"
      "discard=async"
      "space_cache=v2"
      "commit=120"
    ];
  };
  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/dd44e584-a85b-481e-9772-339b1c6ecb7b";
    fsType = "ext4";
  };

  services.zfs.autoScrub.enable = true;

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/scratch" ];
  };
}
