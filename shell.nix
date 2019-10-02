let
nixpkgs = (import <nixpkgs> {}).fetchFromGitHub {
  owner = "NixOS"; repo = "nixpkgs";
  rev = "fbfdaed2105a2ae32fe4ca2d1a5a68e7d78b2b8e";
  sha256 = "0yb1cafl85wqkvkby26hc9pzr2syjw7n7f2ll676h80nyiybkdni";
};
pkgs = import nixpkgs {};
in
with pkgs; mkShell {
  name = "h-shell";
  buildInputs = [
    shunit2
    gitMinimal
    entr
    bash
    zsh
  ];
}
