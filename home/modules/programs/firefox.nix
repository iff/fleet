{ config, lib, pkgs, ... }:

let
  cfg = config.dots.firefox;

  # NOTE GDK_DPI_SCALE= effects firefox if we want a smaller ui
  # wrapped = pkgs.writeShellScriptBin "firefox" "GDK_SCALE= GDK_DPI_SCALE=0.8 exec -a $0 ${pkgs.firefox}/bin/firefox $@";
  # NOTE we use --new-tab so it's always a new tab, even if the firefox setting is different
  dispatch = pkgs.writeScriptBin "firefox-dispatch" ''
    #!${pkgs.zsh}/bin/zsh
    set -eu -o pipefail
    if [[ $1 =~ '(.*eztv\.re.*)|(.*eztvx\.to.*)|(.*thepiratebay\.org.*)' ]]; then
      exec -a $0 firefox --private-window $@
    fi
    exec -a $0 firefox --new-tab $@
  '';

in
{
  options.dots.firefox = {
    enable = lib.mkEnableOption "enable firefox";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.firefox  # TODO HM module for config?
      pkgs.stix-two # maybe for math fonts?
      dispatch
    ];

    xdg = lib.mkIf (pkgs.stdenv.isLinux) {
      enable = true;
      desktopEntries = {
        firefox = {
          name = "firefox";
          genericName = "Web Browser";
          exec = "firefox-dispatch %U";
          terminal = false;
          categories = [ "Application" "Network" "WebBrowser" ];
          mimeType = [ "text/html" "text/xml" ];
        };
      };
      mimeApps = {
        enable = true;
        defaultApplications = {
          "text/html" = "firefox.desktop";
          "x-scheme-handler/http" = "firefox.desktop";
          "x-scheme-handler/https" = "firefox.desktop";
          "x-scheme-handler/about" = "firefox.desktop";
          "x-scheme-handler/unknown" = "firefox.desktop";
        };
      };
    };
  };
}
