with import <nixpkgs> {};
stdenv.mkDerivation rec {
  name = "vdf-blog";
  buildInputs = [
    pkgs.hugo
  ];
}
