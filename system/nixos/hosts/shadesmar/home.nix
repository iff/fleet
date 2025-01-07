{ pkgs, ... }:

let
  wrapped-uv = pkgs.writeScriptBin "uv" ''
    #!${pkgs.zsh}/bin/zsh
    set -eu -o pipefail
    path=(${pkgs.python313}/bin ${pkgs.python310}/bin $path)
    export UV_CACHE_DIR=/scratch/.cache/uv
    ${pkgs.uv}/bin/uv $@
  '';
in
{
  home.packages = with pkgs; [
    _1password-gui
    awscli2
    cmake
    eigen
    geeqie
    google-chrome
    lnav
    spotify
    sshfs
    ssm-session-manager-plugin
    syncthing
    wrapped-uv
  ];

  dots = {
    profiles = {
      dwm.enable = true;
      linux.enable = true;
    };
    alacritty = {
      enable = true;
      font_size = 12.0;
      font_normal = "ZedMono Nerd Font";
    };
    osh.enable = true;
    zen.enable = true;
  };
}
