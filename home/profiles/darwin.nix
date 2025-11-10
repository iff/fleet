{ lib, pkgs, ... }:

with lib;
{
  config = mkIf pkgs.stdenv.isDarwin {
    home.sessionVariables = {
      TERMINFO_DIRS = "$HOME/.nix-profile/share/terminfo:$TERMINFO_DIRS";
    };
  };
}
