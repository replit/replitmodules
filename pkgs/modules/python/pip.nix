pkgs @ { pypkgs, ... }:

let
  pip = import ../../pip {
    inherit pkgs pypkgs;
  };

  config-cache-enabled = pkgs.writeTextFile {
    name = "pip.conf";
    text = ''
      [global]
      user = yes
      disable-pip-version-check = yes
      index-url = https://package-proxy.replit.com/pypi/simple/

      [install]
      use-feature = content-addressable-pool
      content-addressable-pool-symlink = yes
    '';
  };

  config-cache-disabled = pkgs.writeTextFile {
    name = "pip.conf";
    text = ''
      [global]
      user = yes
      disable-pip-version-check = yes
    '';
  };
in
pkgs.writeShellScriptBin "pip" ''
  if [[ -n "$__REPLIT_PIP_CACHE_ENABLE" ]]; then
    export PIP_CONFIG_FILE=${config-cache-enabled}
  else
    export PIP_CONFIG_FILE=${config-cache-disabled}
  fi

  exec "${pip}/bin/pip" "$@"
''