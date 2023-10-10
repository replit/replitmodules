{ system
, bash
, lib
, bundle-locked
, revstring
, lkl
, coreutils
, findutils
, e2fsprogs
, closureInfo
, jq
, upgrade-maps
, active-modules
, fetchFromGitHub
}:

let
  label = "nixmodules-${revstring}";
  registry = ../../modules.json;
  # wating for upstream to include our patch: https://github.com/lkl/linux/pull/532
  lkl' = lkl.overrideAttrs (oldAttrs: {
    src = fetchFromGitHub {
      owner = "numtide";
      repo = "linux-lkl";
      rev = "7a337bf313c82713f33f7b2e3c0b8847857a78b6";
      sha256 = "sha256-MfOprw5n7kFOzu5Sl2hVG7+/Q22nKgCWGMO6HYN+SvU=";
    };
  });
in

derivation {
  name = label;
  builder = "${bash}/bin/bash";
  args = [ ./builder.sh ];
  inherit system;
  __structuredAttrs = true;
  unsafeDiscardReferences.out = true;
  env = {
    inherit label registry;
    PATH = lib.makeBinPath [
      coreutils
      findutils
      lkl'
      e2fsprogs
      jq
    ];
    inherit upgrade-maps;
    inherit active-modules;
    blockSize = toString (4 * 1024); # ext4fs block size (not block device sector size)
    diskClosureInfo = closureInfo { rootPaths = [ bundle-locked registry ]; };
  };
}
