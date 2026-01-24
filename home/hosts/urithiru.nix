{ pkgs, ... }:

let
  switch = pkgs.writeScriptBin "switch" ''
    #!/usr/bin/env zsh
    set -eu -o pipefail

    home-manager switch --flake '.#urithiru' -v --log-format internal-json |& ${pkgs.nix-output-monitor}/bin/nom --json
  '';
in
{
  home.stateVersion = "24.05";

  home.packages = [
    switch
    pkgs.zsh
  ];

  dots = {
    alacritty = {
      enable = true;
      decorations = "Full";
      font_size = 19.0;
      font_normal = "ZedMono Nerd Font";
    };
    firefox.enable = false;
    kanata.enable = true;
    zed.enable = true;
  };
}
