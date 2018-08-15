{nixpkgs ? import <nixpkgs> {}}:

with nixpkgs;

rec {
  server = pkgs.writeShellScriptBin "script.sh" ''
    CMD="hugo server -FD"
    if test -n "$TMUX"; then
      tmux split-pane -p15 $CMD
    else
      $CMD
    fi
  '';
}
