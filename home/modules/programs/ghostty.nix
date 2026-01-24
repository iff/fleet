{ ... }:

{
  # currently only nix installed on kharbranth
  home.packages = [ ];

  xdg.configFile."ghostty/config".source = ./ghostty/ghostty.config;
}
