{nixpkgs ? import <nixpkgs> {}}:

with nixpkgs;

rec {
  server = pkgs.writeShellScriptBin "script.sh" ''
    CMD="${pkgs.hugo}/bin/hugo server --buildFuture --buildDrafts --bind=0.0.0.0"
    if test -n "$TMUX"; then
      tmux split-pane -p15 $CMD
    else
      $CMD
    fi
  '';
}
