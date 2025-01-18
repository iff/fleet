{ config, lib, ... }:

with lib;
let
  cfg = config.dots.syncthing;
  dataDir = "${config.home.homeDirectory}/sync";
in
{
  options.dots.syncthing = {
    enable = mkEnableOption "enable syncthing";
  };

  config = mkIf cfg.enable
    {
      services.syncthing = {
        enable = true;
        extraOptions = [ "--config" "${dataDir}/.config/syncthing" "--data" "${dataDir}" "--no-default-folder" ];
        overrideFolders = true;
        overrideDevices = true;
        settings = {
          options.urAccepted = -1;
          devices = {
            kharbranth = { id = "FX6KDKI-UPZE5RA-KEL7OX7-WER52KY-6WVQ6CY-HNK3UX3-23W3CEK-3HWTMAY"; };
            shadesmar = { id = "QWXKQOD-JWPR4VE-KQBV47P-HU33L32-TTKOG75-6LKCKGG-PJH3CQ2-SVNHMAR"; };
          };
          folders = {
            work = {
              path = "~/sync/work";
              devices = [ "kharbranth" "shadesmar" ];
            };
          };
        };
      };
    };
}
