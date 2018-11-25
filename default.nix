#!/usr/bin/env nix-build

{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
     name = "blog-site";
     src = ./.;
     phases = "unpackPhase buildPhase";
     buildInputs = with pkgs; [ hugo ];
     buildPhase = ''
       LANG=en_US.UTF-8 hugo
       mkdir $out
       cp -r public/* $out
     '';
}

