{ config, pkgs, ... }: {

  home.file = {
    ".zshenv".source = ./zsh/zshenv;
    ".zshrc".source = ./zsh/zshrc;
    ".zshrc.d" = {
      recursive = true;
      source = ./zsh/zshrcd;
    };
    # TODO that should come as a flake input? or can we keep it as submodules? it makes it complicated with recursive above
    ".zshrc.d/zsh-syntax-highlighting".source = pkgs.fetchFromGitHub {
      owner = "zsh-users";
      repo = "zsh-syntax-highlighting";
      rev = "e0165eaa730dd0fa321a6a6de74f092fe87630b0";
      sha256 = "sha256-4rW2N+ankAH4sA6Sa5mr9IKsdAg7WTgrmyqJ2V1vygQ=";
    };
  };
}
