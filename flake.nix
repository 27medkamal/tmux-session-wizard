{
  description = "Tmux session manager plugin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  };

  outputs = { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      # lib = pkgs.lib;
    in
    {
      packages.x86_64-linux.default = pkgs.callPackage ./default.nix { };

      devShells.x86_64-linux.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          (bats.withLibraries (p: [ p.bats-support p.bats-assert p.bats-file p.bats-detik ]))
          watchexec
        ];
      };
    };

}
