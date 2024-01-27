{ nixpkgs ? <nixpkgs> }:
let
  pkgs = import nixpkgs { };
  lib = pkgs.lib;
in
pkgs.tmuxPlugins.mkTmuxPlugin {
  pluginName = "session-wizard";
  rtpFilePath = "session-wizard.tmux";
  version = "unstble";
  src = ./.;
  # src = builtins.fetchGit {
  #   url = "/workspace/tmux/tmux-session-wizard";
  #   # url = builtins.path "./.";
  # };
  meta = with lib; {
    homepage = "https://github.com/27medkamal/tmux-session-wizard";
    description = "Tmux plugin for creating and switching between sessions based on recently accessed directories";
    longDescription = ''
      Session Wizard is using fzf and zoxide to do all the magic. Features:
      * Creating a new session from a list of recently accessed directories
      * Naming a session after a folder/project
      * Switching sessions
      * Viewing current or creating new sessions in one popup
    '';
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = with maintainers; [ mandos ];
  };
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postInstall = ''
    substituteInPlace $target/session-wizard.tmux \
      --replace  \$CURRENT_DIR/session-wizard.sh $target/session-wizard.sh
    wrapProgram $target/session-wizard.sh \
      --prefix PATH : ${with pkgs; lib.makeBinPath ([ fzf zoxide coreutils gnugrep gnused ])}
  '';
}
