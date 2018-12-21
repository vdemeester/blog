with import <nixpkgs> {};
stdenv.mkDerivation {
  name = "ape";
  buildInputs = with pkgs; [
    hugo
  ];
}
