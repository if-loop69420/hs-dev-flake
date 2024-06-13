{
  description = "Flake i stole to use stack for haskell...";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: let
    forAllSystems = function: 
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
      ] (system: function nixpkgs.legacyPackages.${system});
  in {
    devShells = forAllSystems (pkgs:
      let
        hPkgs = pkgs.haskell.packages.ghc965; # LTS-22.25

        devTools = [
          hPkgs.ghc # GHC compiler in the desired version (will be available on PATH)
          hPkgs.ghcid # Continuous terminal Haskell compile checker
          hPkgs.ormolu # Haskell formatter
          hPkgs.hlint # Haskell codestyle checker
          hPkgs.cabal-install
          hPkgs.hoogle # Lookup Haskell documentation
          hPkgs.haskell-language-server # LSP server for editor
          hPkgs.implicit-hie # auto generate LSP hie.yaml file from cabal
          hPkgs.retrie # Haskell refactoring tool
          # hPkgs.cabal-install
          stack-wrapped
        ];

        stack-wrapped = pkgs.symlinkJoin {
          name = "stack"; # will be available as the usual `stack` in terminal
          paths = [ pkgs.stack ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/stack \
              --add-flags "\
                --system-ghc \
                --no-install-ghc \
              "
          '';
        };
      in {
        default = pkgs.mkShell {
          buildInputs = devTools;

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath devTools;
        };
      }
    );
  };
}
