{ pkgs, ... }:

let
  # TODO see https://docs.astral.sh/uv/configuration/environment/
  uvBin = pkgs.writeScriptBin "uv" ''
    #!${pkgs.zsh}/bin/zsh
    set -eu -o pipefail
    export path=(${pkgs.python313}/bin ${pkgs.python310}/bin $path)
    export UV_PYTHON_PREFERENCE=only-system
    export UV_CACHE_DIR=/scratch/.cache/uv
    ${pkgs.uv}/bin/uv $@
  '';
  uvxBin = pkgs.writeScriptBin "uvx" ''
    #!${pkgs.zsh}/bin/zsh
    set -eu -o pipefail
    export path=(${pkgs.python313}/bin ${pkgs.python310}/bin $path)
    export UV_PYTHON_PREFERENCE=only-system
    export UV_CACHE_DIR=/scratch/.cache/uv
    ${pkgs.uv}/bin/uvx $@
  '';
  wrapped-uv = pkgs.symlinkJoin {
    name = "wrapped-uv";
    # NOTE symlinkJoin allows clashes, the first in the list wins
    paths = [ uvBin uvxBin pkgs.uv ];
  };
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
