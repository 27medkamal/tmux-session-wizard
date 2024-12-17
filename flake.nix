{
  inputs = { flake-utils.url = "github:numtide/flake-utils"; };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        devPackages = [
          (pkgs.bats.withLibraries (p: [ p.bats-support p.bats-assert ]))
          pkgs.watchexec
        ];

        plugin = pkgs.tmuxPlugins.mkTmuxPlugin {
          pluginName = "session-wizard";
          rtpFilePath = "session-wizard.tmux";
          version = "unstable";
          src = self;
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postInstall = ''
            substituteInPlace $target/session-wizard.tmux --replace  \$CURRENT_DIR $target
            wrapProgram $target/bin/t \
              --prefix PATH : ${
                with pkgs;
                lib.makeBinPath ([ fzf zoxide coreutils gnugrep gnused ])
              }
          '';
        };
      in {
        packages.default = plugin;

        packages.dev = (pkgs.symlinkJoin {
          name = "dev-environment";
          paths = [
            plugin
            plugin.buildInputs
            pkgs.tmux
            pkgs.bashInteractive
            pkgs.busybox
            pkgs.zoxide
          ] ++ devPackages;
        });

        devShell = pkgs.mkShell { buildInputs = devPackages; };
      });
}
