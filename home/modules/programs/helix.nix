{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.dots.helix;
in
{
  options.dots.helix = {
    enable = lib.mkEnableOption "enable helix";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.helix ];
    home.file.".config/helix".source = ./helix;
  };
}
