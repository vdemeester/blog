with import <nixpkgs> {};
pkgs.stdenv.mkDerivation rec {
  name = "vdf-blog";
  env = pkgs.buildEnv { name = name; paths = buildInputs; };
  buildInputs = [
    pkgs.hugo
  ];
}
