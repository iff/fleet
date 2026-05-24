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

  home.sessionPath = [
    "$HOME/.nix-profile/bin"
    "/nix/var/nix/profiles/default/bin"
  ];

  home.packages = [
    switch
    pkgs.zsh
  ];

  dots = {
    alacritty = {
      enable = true;
      decorations = "Full";
      font_size = 19.0;
      font_normal = "IosevkaTerm Nerd Font Mono";
      font_style = "Light";
    };
    helix.enable = true;
    firefox.enable = false;
    kanata.enable = true;
    zed.enable = true;
  };

  # launchd.agents.nix-gc = {
  #   enable = true;
  #   config = {
  #     ProgramArguments = [
  #       "/bin/sh" "-c"
  #       "nix-collect-garbage --delete-older-than 30d && nix profile wipe-history --profile $HOME/.local/state/nix/profiles/profile --older-than 30d"
  #     ];
  #     StartCalendarInterval = [{ Weekday = 0; Hour = 3; Minute = 0; }];
  #     StandardOutPath = "/tmp/nix-gc.log";
  #     StandardErrorPath = "/tmp/nix-gc.log";
  #   };
  # };
}
