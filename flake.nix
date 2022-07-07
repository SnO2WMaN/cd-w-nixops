{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    devshell.url = "github:numtide/devshell";
    flake-utils.url = "github:numtide/flake-utils";
    nixops-plugged.url = "github:lukebfox/nixops-plugged";

    hercules-ci-effects.url = "github:hercules-ci/hercules-ci-effects";
    hercules-ci-agent.url = "github:hercules-ci/hercules-ci-agent";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    flake-compat-ci.url = "github:hercules-ci/flake-compat-ci";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    devshell,
    nixops-plugged,
    hercules-ci-agent,
    hercules-ci-effects,
    flake-compat-ci,
    flake-parts,
    ...
  }:
    flake-utils.lib.eachSystem ["x86_64-linux"] (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            devshell.overlay
            hercules-ci-agent.overlay
            (final: prev: nixops-plugged.packages."${system}")
          ];
        };
      in {
        devShells.default = pkgs.devshell.mkShell {
          imports = [
            (pkgs.devshell.importTOML ./devshell.toml)
          ];
        };
      }
    )
    // {
      nixopsConfigurations = {
        default = import ./nixops {inherit nixpkgs;};
      };
      herculesCI = {...}: {
        onPush.default = {
          outputs.effects = let
            pkgs = import nixpkgs {
              system = "x86_64-linux";
              overlays = [
                hercules-ci-effects.overlay
                (final: prev: nixops-plugged.packages."x86_64-linux")
              ];
            };
          in {
            nixops = pkgs.effects.runNixOps2 {
              flake = self;
            };
          };
        };
      };
    };
}
