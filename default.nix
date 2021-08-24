{ pkgs ? import <tuat> {} }:

let
  lua = pkgs.luajit.withPackages(lp: [
    lp.cjson
    lp.etlua
    lp.luasocket
    lp.luasql-sqlite3
    lp.lua_cliargs
    lp.net-url
    lp.router
  ]);

  src = ./.;
  path = map (pkg: "${pkg}/bin") [
    lua
    pkgs.coreutils
    pkgs.twurl
    pkgs.sqlite
    pkgs.w3m
  ];

  tuat = ''
    export PATH=${builtins.concatStringsSep ":" path}:$PATH

    if [[ -z "$LUA_PATH" ]]; then
      export LUA_PATH="${src}/?.lua;${src}/?/init.lua;;"
    fi
    if [[ -z "$TUAT_LAYOUTS" ]]; then
      export TUAT_LAYOUTS=${src}/layouts
    fi
    if [[ -z "$TUAT_CACHE" ]]; then
      export TUAT_CACHE=$HOME/.cache/tuat
      mkdir -p $TUAT_CACHE
    fi

    if [ "$1" = "authorize" ]; then
      shift
      twurl authorize "$@"
    elif [ "$1" = "cache" ]; then
      shift
      if [ "$1" = "follows" ]; then
        shift
        for user in "$@"; do
          lua ${src}/tuat/cache/follows.lua $user
        done
      else
        sqlite3 $TUAT_CACHE/tuat.sqlite "$@"
      fi
    elif [ "$1" = "view" ]; then
      shift
      if [[ -n "$REQUEST_METHOD" ]]; then
        lua ${src}/tuat/view.lua
      elif [[ "$*" == *--format* ]]; then
        lua ${src}/tuat/view.lua "$@"
      else
        lua ${src}/tuat/view.lua "$@" | w3m -T text/html
      fi
    fi
  '';

in pkgs.stdenv.mkDerivation {
  pname = "tuat";
  version = "0.0.0-dev";

  inherit src tuat;
  passAsFile = [ "tuat" ];

  installPhase = ''
    mkdir -p $out/bin
    mv $tuatPath $out/bin/tuat
    chmod +x $out/bin/tuat
  '';
}
