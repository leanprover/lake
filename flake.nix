{
  description = "Lake (Lean Make) is a new build system and package manager for Lean 4.";

  inputs = {
    lean.url = "github:leanprover/lean4";
    nixpkgs.follows = "lean/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { flake-utils
    , nixpkgs
    , lean
    , ...
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      packageName = "Lake";
      src = ./.;
      leanPkgs = lean.packages.${system};
      project = leanPkgs.buildLeanPackage {
        inherit src;
        name = packageName;
      };
      cli = leanPkgs.buildLeanPackage {
        inherit src;
        name = "Lake.Main";
        executableName = "lake";
        deps = [ project ];
        linkFlags = pkgs.lib.optional pkgs.stdenv.isLinux "-rdynamic";
      };
    in
    {
      inherit project;
      packages = {
        inherit (leanPkgs) lean;
        cli = cli.executable;
        default = cli.executable;
      };

      apps = rec {
        lake = flake-utils.lib.mkApp { drv = cli.executable; };
        default = lake;
      };

      devShells = rec {
        lake = project.devShell;
        default = lake;
      };
    });
}
