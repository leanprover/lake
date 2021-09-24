{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05";
    lean = {
      url = "github:leanprover/lean4";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , flake-utils
    , nixpkgs
    , lean
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      packageName = "Lake";
      src = ./.;
      leanPkgs = lean.packages.${system};
      inherit (leanPkgs) leanc stage1;
      inherit (pkgs.lib) concatStrings debug;
      project = leanPkgs.buildLeanPackage {
        name = packageName;
        inherit src;
      };
    in
    {
      packages.${packageName} = project.lean-package;

      defaultPackage = self.packages.${system}.${packageName};

      apps.lake = flake-utils.lib.mkApp {
        name = "lake";
        drv = project.executable;
      };

      defaultApp = self.apps.${system}.lake;

      # `nix develop`
      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [
          leanPkgs.lean
        ];
      };
    });
}
