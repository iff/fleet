{ inputs, ... }:

with inputs.nixpkgs.lib;
let
  strToPath =
    x: path: if builtins.typeOf x == "string" then builtins.toPath ("${toString path}/${x}") else x;
  strToFile =
    x: path: if builtins.typeOf x == "string" then builtins.toPath ("${toString path}/${x}.nix") else x;
in
rec {
  mkUserHome =
    { config }:
    { lib, pkgs, ... }:
    {
      imports = [
        (import ../home/common)
        (import ../home/modules)
        (import ../home/profiles)
        (import config) # eg. home/hosts/darktower.nix
      ];

      # For compatibility with nix-shell, nix-build, etc.
      home.file.".nixpkgs".source = inputs.nixpkgs;
      home.sessionVariables."NIX_PATH" = "nixpkgs=$HOME/.nixpkgs\${NIX_PATH:+:}$NIX_PATH";

      # nvd diff after home-manager activation
      # TODO also shows diff if nothing changed..
      home.activation.report-changes = lib.hm.dag.entryAfter [ "installPackages" ] ''
        PATH=$PATH:${
          lib.makeBinPath [
            pkgs.nvd
            pkgs.nix
          ]
        }
        if [[ -d ~/.local/state/nix/profiles ]]; then
          nvd diff $(find ~/.local/state/nix/profiles -name "home-manager-*-link" -type l | sort -V | tail -2) || echo "No previous home-manager generation found"
        fi
      '';

      # set in host? fallback
      home.stateVersion = "24.05";
    };

  intoHomeManager =
    name:
    {
      config ? name,
      user ? "iff",
      system ? "x86_64-linux",
    }:
    let
      pkgs = inputs.self.pkgsBySystem."${system}";
      username = user;
      homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
    in
    nameValuePair name (
      inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          {
            home = { inherit username homeDirectory; };

            imports =
              let
                userConf = strToFile config ../home/hosts;
                home = mkUserHome { config = userConf; };
              in
              [ home ];

            nix = {
              settings = {
                substituters = [
                  "https://cache.nixos.org"
                  "https://iff-dotfiles.cachix.org"
                  # "https://cachix.cachix.org"
                  # "https://nix-community.cachix.org"
                ];
                trusted-public-keys = [
                  "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                  "iff-dotfiles.cachix.org-1:9PzCJ44z3MuyvrvjkbbMWCDl5Rrf9nt3OZHq446Wn58="
                  # "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
                  # "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                ];
              };
              package = pkgs.nixVersions.stable;
              extraOptions = "experimental-features = nix-command flakes";
            };

            nixpkgs = {
              overlays = [ ];
            };
          }
        ];
        extraSpecialArgs =
          let
            self = inputs.self;
          in
          {
            inherit inputs name self;
          };
      }
    );

  intoNixOs =
    name:
    {
      config ? name,
      user ? "iff",
      system ? "x86_64-linux",
    }:
    nameValuePair name (
      let
        pkgs = inputs.self.pkgsBySystem."${system}";
      in
      nixosSystem {
        modules = [
          (
            { name, ... }:
            {
              networking.hostName = name;
            }
          )
          (
            { inputs, ... }:
            {
              nixpkgs = {
                inherit pkgs;
                hostPlatform = system;
                overlays = [
                  # Waybar overlay for experimental features (used by hyprland/sway profiles)
                  (final: prev: {
                    waybar = prev.waybar.overrideAttrs (oldAttrs: {
                      mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
                    });
                  })
                ];
              };

              environment.etc.nixpkgs.source = inputs.nixpkgs;
              nix.nixPath = [ "nixpkgs=/etc/nixpkgs" ];
            }
          )
          (
            { pkgs, ... }:
            {
              nix = {
                package = pkgs.nixVersions.latest;
                extraOptions = "experimental-features = nix-command flakes";
              };
            }
          )
          (
            { inputs, ... }:
            {
              # re-expose self and nixpkgs as flakes.
              nix.registry = {
                self.flake = inputs.self;
                nixpkgs = {
                  from = {
                    id = "nixpkgs";
                    type = "indirect";
                  };
                  flake = inputs.nixpkgs;
                };
              };
            }
          )
          (
            { ... }:
            {
              system.stateVersion = "24.05";
            }
          )
          (inputs.home-manager.nixosModules.home-manager)
          ({
            home-manager = {
              useGlobalPkgs = true;
              extraSpecialArgs =
                let
                  self = inputs.self;
                in
                # NOTE: Cannot pass name to home-manager as it passes `name` in to set the `hmModule`
                {
                  inherit inputs self user;
                };
            };
          })
          (import ../system/nixos/profiles)
          (import (strToPath config ../system/nixos/hosts))
        ];
        specialArgs =
          let
            self = inputs.self;
          in
          {
            inherit
              inputs
              name
              self
              user
              ;
          };
      }
    );
}
