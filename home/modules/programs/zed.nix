{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.dots.zed;
in
{
  options.dots.zed = {
    enable = lib.mkEnableOption "enable zed";
  };

  config = mkIf cfg.enable {
    # Zed currently installed manually to have latest version
    home.packages = [ ];
    home.file.".config/zed/keymap.json".source = ./zed/keymap.json;
    home.file.".config/zed/settings.json".source = ./zed/settings.json;
  };
}
