{ pkgs ? import ../pkgs {} }:

let
  tuat = import ./default.nix {};

in pkgs.mkShell {
  nativeBuildInputs = [ tuat ];
  shellHook = ''
    source ${tuat}/bin/tuat
    export LUA_PATH="$(pwd)/?.lua;$(pwd)/?/init.lua;;"
    export TUAT_LAYOUTS=$(pwd)/layouts
  '';
}
