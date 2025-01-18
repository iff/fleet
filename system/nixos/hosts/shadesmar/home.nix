{ pkgs, ... }:

let
  # TODO what template to use? and where to get it from?
  mkenv = pkgs.writeScriptBin "mkenv"
    ''
      #!/bin/zsh
      set -eu -o pipefail

      env=$HOME/envs/$1
      mkdir -p env
      echo 'use flake "$HOME/src/dev-templates/nn"' > env/.envrc
    '';
in
{
  home.packages = with pkgs; [
    geeqie
    syncthing
    # work
    awscli2
    ssm-session-manager-plugin
    # own
    mkenv
  ];

  services.blueman-applet.enable = true;

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
    syncthing.enable = true;
    zen.enable = true;
  };
}
