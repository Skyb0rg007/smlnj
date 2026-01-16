# COPYRIGHT (c) 2025 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#
# Nix development shell for SML/NJ.
#
# usage: nix develop -f shell.nix
# 
{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  packages = [
    pkgs.autoconf
    pkgs.automake
    pkgs.cmake
    pkgs.git
    pkgs.ninja
    pkgs.python3
  ];
}
