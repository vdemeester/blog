#!/usr/bin/env nix-build
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
  site = pkgs.stdenv.mkDerivation {
     name = "blog-site";
     src = ./.;
     phases = "unpackPhase buildPhase";
     buildInputs = with pkgs; [ hugo ];
     buildPhase = ''
       LANG=en_US.UTF-8 hugo
       mkdir $out
       cp -r public/* $out
     '';
  };
}
