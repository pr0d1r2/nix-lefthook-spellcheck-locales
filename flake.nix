{
  description = "Lefthook-compatible locale spellchecker (keys + values), packaged as a Nix flake";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-dev-shell-agentic = {
      url = "github:pr0d1r2/nix-dev-shell-agentic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-unicode-lint = {
      url = "github:pr0d1r2/nix-lefthook-unicode-lint";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-dev-shell-agentic,
      ...
    }@inputs:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (
        pkgs:
        let
          rubyEnv = [
            pkgs.ruby
            pkgs.hunspell
            pkgs.hunspellDicts.en_US
          ];
          keysScript = pkgs.writeText "lefthook-spellcheck-locales-keys.rb" (
            builtins.readFile ./lefthook-spellcheck-locales-keys.rb
          );
          valuesScript = pkgs.writeText "lefthook-spellcheck-locales-values.rb" (
            builtins.readFile ./lefthook-spellcheck-locales-values.rb
          );
        in
        {
          lefthook-spellcheck-locales-keys = pkgs.writeShellApplication {
            name = "lefthook-spellcheck-locales-keys";
            runtimeInputs = rubyEnv;
            text = ''
              exec ruby ${keysScript} "$@"
            '';
          };
          lefthook-spellcheck-locales-values = pkgs.writeShellApplication {
            name = "lefthook-spellcheck-locales-values";
            runtimeInputs = rubyEnv;
            text = ''
              exec ruby ${valuesScript} "$@"
            '';
          };
          default = pkgs.symlinkJoin {
            name = "lefthook-spellcheck-locales";
            paths = [
              self.packages.${pkgs.stdenv.hostPlatform.system}.lefthook-spellcheck-locales-keys
              self.packages.${pkgs.stdenv.hostPlatform.system}.lefthook-spellcheck-locales-values
            ];
          };
        }
      );

      devShells = forAllSystems (
        pkgs:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
          shells = nix-dev-shell-agentic.lib.mkShells {
            inherit pkgs inputs;
            ciPackages = [
              self.packages.${system}.default
              pkgs.hunspell
              pkgs.hunspellDicts.en_US
            ];
            shellHook = builtins.replaceStrings [ "@BATS_LIB_PATH@" ] [ "${shells.batsWithLibs}" ] (
              builtins.readFile ./dev.sh
            );
          };
        in
        shells
      );
    };
}
