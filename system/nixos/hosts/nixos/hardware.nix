{ config, lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
    initrd = {
      availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" ];
      kernelModules = [ "dm-snapshot" ];
    };

    loader = {
      timeout = 0; # TODO or null for wait, or 0 for on-key?
      efi = {
        canTouchEfiVariables = true;
        # TODO why do I have that enabled?
        efiSysMountPoint = "/boot/efi";
      };
      systemd-boot = {
        enable = true;
        configurationLimit = 100;
        consoleMode = "0"; # all options often take long to appear
      };
    };

    supportedFilesystems = [ "btrfs" ];
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/346d26c9-5545-4606-bbc8-17a7a620369f"; }];


  fileSystems."/" =
    {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [ "noatime" "ssd" "discard=async" "space_cache=v2" "commit=120" ];
      # compress=zstd:1
    };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/" ];
  };

  fileSystems."/boot/efi" =
    {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

  fileSystems."/mirrored" =
    {
      device = "/dev/darktower/nixos";
      fsType = "ext4";
    };

  # powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
