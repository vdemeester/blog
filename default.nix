with import <nixpkgs> {};
stdenv.mkDerivation {
  name = "blog";
  buildInputs = with pkgs; [
    hugo
  ];
}
