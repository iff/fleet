{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

with lib;
let
  cfg = config.dots.helix;
  helix = inputs.iff-helix.packages.${pkgs.stdenv.hostPlatform.system}.helix;
  h = pkgs.writeScriptBin "h" ''
    #!/usr/bin/env zsh
    set -eu -o pipefail
    ${helix}/bin/hx $@
  '';
in
{
  options.dots.helix = {
    enable = lib.mkEnableOption "enable helix";
  };

  config = mkIf cfg.enable {
    home.packages = [
      h
    ];
    home.file.".config/helix".source = ./helix;
  };
}
