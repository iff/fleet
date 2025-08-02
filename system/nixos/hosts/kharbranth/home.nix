{ pkgs, ... }:

let
  gpr = pkgs.writeScriptBin "gpr"
    ''
      #!/usr/bin/env zsh
      set -eu -o pipefail

      gh pr create --editor --fill-verbose
    '';

  wt = pkgs.writeScriptBin "wt"
    ''
      #!/usr/bin/env zsh
      set -eu -o pipefail

      name=''${1?-worktree name}
      [[ ! -v 2 ]]

      sha=$(git rev-parse HEAD)
      git worktree add --detach $(realpath wt/$name) $sha
      # maybe zsh subshell in this path and remove/purge when returning?
      echo "new tree: $(realpath wt/$name)"
    '';
in
{
  home.packages = with pkgs; [
    # ‘libsoup-2.74.3’ is marked as insecure, refusing to evaluate
    # geeqie
    claude-code
    gh
    google-chrome
    neovide
    protonmail-desktop
    roam-research
    spotify
    transmission_4-gtk
    vlc
    #
    gpr
    wt
  ];

  dots = {
    profiles = {
      hyprland.enable = true;
      linux.enable = true;
    };
    alacritty = {
      enable = true;
      font_size = 14.0;
      font_normal = "ZedMono Nerd Font";
    };
    osh.enable = true;
    # syncthing.enable = true;
    firefox.enable = true;
  };
}
