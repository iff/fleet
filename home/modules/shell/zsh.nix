{ inputs, pkgs, ... }:

{

  home.file = {
    ".config/zsh-patina/config.toml".source = ./zsh/config.toml;
    ".zshenv".source = ./zsh/zshenv;
    ".zshrc".source = ./zsh/zshrc;
    ".zshrc.d" = {
      recursive = true;
      source = ./zsh/zshrcd;
    };

    ".zshrc.d/nd.zsh".source = "${
      inputs.nd.packages.${pkgs.stdenv.hostPlatform.system}.shell
    }/share/nd/activate.zsh";
  };

  home.packages = [
    inputs.osh-oxy.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.zsh-patina
  ];
}
