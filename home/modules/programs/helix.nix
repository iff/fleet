{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.dots.helix;
  h = pkgs.writeScriptBin "h" ''
    #!/usr/bin/env zsh
    set -eu -o pipefail
    hx $@
  '';
in
{
  options.dots.helix = {
    enable = lib.mkEnableOption "enable helix";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.helix
      h
    ];
    home.file.".config/helix".source = ./helix;
  };
}
