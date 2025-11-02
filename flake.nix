{
  description = "home manager flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hypr-contrib = {
      url = "github:hyprwm/contrib";
    };

    iff-dwm = {
      url = "github:iff/dwm/nixos";
      flake = false;
    };

    osh-oxy = {
      url = "github:iff/osh-oxy";
      inputs.nixpkgs.follows = "nixpkgs";
      flake = true;
    };

    nihilistic-nvim = {
      url = "github:iff/nihilistic-nvim";
      inputs.nixpkgs.follows = "nixpkgs";
      flake = true;
    };

    zsh-syntax-highlighting = {
      url = "github:zsh-users/zsh-syntax-highlighting";
      flake = false;
    };

    ltstatus = {
      url = "github:dkuettel/ltstatus/main";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://iff-dotfiles.cachix.org"
    ];
    extra-trusted-public-keys = [
      "iff-dotfiles.cachix.org-1:9PzCJ44z3MuyvrvjkbbMWCDl5Rrf9nt3OZHq446Wn58="
    ];
    extra-experimental-features = "nix-command flakes";
  };

  outputs = { self, flake-utils, home-manager, ... } @ inputs:
    with self.lib;

    let
      forEachSystem = genAttrs [ "x86_64-linux" "aarch64-darwin" ];
      pkgsBySystem = forEachSystem (system:
        import inputs.nixpkgs {
          inherit system;

          config.allowUnfreePredicate = pkg: builtins.elem (self.lib.getName pkg)
            [ "1password" "1password-gui" "1password-cli" "claude-code" "google-chrome" "keymapp" "nvidia-settings" "nvidia-x11" "roam-research" "spotify" "steam" "steam-unwrapped" ];
        }
      );

    in
    {
      inherit pkgsBySystem;
      lib = import ./lib { inherit inputs; } // inputs.nixpkgs.lib;

      homeConfigurations = mapAttrs' intoHomeManager {
        # roshar = { system = "aarch64-darwin"; };
        urithiru = { system = "aarch64-darwin"; };
      };

      nixosConfigurations = mapAttrs' intoNixOs {
        kharbranth = { };
        # shadesmar = { user = "yineichen"; };
      };

      # CI build helper
      top =
        let
          systems = genAttrs
            (builtins.attrNames inputs.self.nixosConfigurations)
            (attr: inputs.self.nixosConfigurations.${attr}.config.system.build.toplevel);
          homes = genAttrs
            (builtins.attrNames inputs.self.homeConfigurations)
            (attr: inputs.self.homeConfigurations.${attr}.activationPackage);
        in
        systems // homes;
    };
}
