{ pkgs, inputs, ... }:

let
  np = pkgs.writeScriptBin "np" ''
    #!/usr/bin/env zsh
    set -eu -o pipefail

    if [[ $# -ne 2 ]]; then
      echo "usage: np <name> <language>" >&2
      exit 1
    fi

    name=$1
    lang=$2
    envs=$HOME/src/envs
    template=$envs/$lang

    if [[ ! -d $template ]]; then
      echo "unknown language '$lang', available:" >&2
      ls $envs >&2
      exit 1
    fi

    dest=$HOME/src/$name

    if [[ -e $dest ]]; then
      echo "$dest already exists" >&2
      exit 1
    fi

    mkdir -p $dest
    cp $template/flake.nix $dest/flake.nix
    echo 'use flake' > $dest/.envrc

    cd $dest
  '';
in
{
  home.stateVersion = "24.05";

  # TODO: https://nix-community.github.io/home-manager/#sec-install-nixos-module
  # do we need to set?:
  # home-manager.useUserPackages = true;
  # home-manager.useGlobalPkgs = true;

  programs.home-manager.enable = true;
  manual.manpages.enable = true; # home-manager man pages
  programs.man.enable = true; # nix pkgs man pages

  fonts.fontconfig.enable = true;

  home.packages = [
    np
    pkgs._1password-cli
    pkgs.dua
    pkgs.eza
    pkgs.fd
    pkgs.jq
    pkgs.dix
    pkgs.procs
    # fonts
    pkgs.fontconfig
    # pkgs.nerd-fonts.zed-mono
    pkgs.nerd-fonts.iosevka-term
    # all systems with nvim
    inputs.nihilistic-nvim.packages.${pkgs.stdenv.hostPlatform.system}.default
    # try
    pkgs.claude-code
    inputs.nd.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  programs.direnv = {
    enable = true;
    config = {
      hide_env_diff = true;
    };
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = false;
    enableFishIntegration = false;
    enableZshIntegration = false;
  };

  home.file.".lesskey".text = ''
    #command
    e forw-line
    u back-line
    n left-scroll
    i right-scroll
    h forw-screen
    H forw-forever
    ^h goto-end
    k back-screen
    ^k goto-line
    r repaint
    E repeat-search
    U reverse-search
    ff clear-search
  '';

}
