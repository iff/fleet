{ pkgs, ... }:

let
  switch = pkgs.writeScriptBin "switch"
    ''
      #!/usr/bin/env zsh
      set -eu -o pipefail

      home-manager switch --flake '.#urithiru'
    '';
in
{
  home.stateVersion = "24.05";

  home.packages = [
    switch
  ];

  dots = {
    alacritty = {
      enable = true;
      font_size = 19.0;
      font_normal = "ZedMono Nerd Font";
    };
    firefox.enable = true;
    kanata.enable = true;
  };
}
