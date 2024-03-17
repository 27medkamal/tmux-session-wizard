{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs, ... }:

    let
      system = "x86_64-linux";
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
          substituteInPlace $target/session-wizard.tmux \
            --replace  \$CURRENT_DIR/session-wizard.sh $target/session-wizard.sh
          wrapProgram $target/session-wizard.sh \
            --prefix PATH : ${with pkgs; lib.makeBinPath ([ fzf zoxide coreutils gnugrep gnused ])}
        '';
      };
    in
    {
      packages.x86_64-linux.dev = pkgs.symlinkJoin
        {
          name = "dev-environment";
          paths = [
            plugin
            # plugin.buildInputs
            pkgs.tmux
            pkgs.bashInteractive
            pkgs.busybox
          ] ++ devPackages;
        };

      devShell.x86_64-linux = pkgs.mkShell {
        buildInputs = devPackages;
      };
    };
}
