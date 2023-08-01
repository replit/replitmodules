{ pkgs
, revstring
, modulesLocks
, mkPhonyOCI
}:

with pkgs.lib;

let
  commits = unique (catAttrs "commit" (builtins.attrValues modulesLocks));

  flakes = builtins.listToAttrs (
    map
      (commit: {
        name = commit;
        value = builtins.getFlake "github:replit/nixmodules/${commit}";
      })
      commits);

  phonyOCIs = builtins.mapAttrs
    (name: module:
      let
        module-id = elemAt (strings.splitString ":" name) 0;
        m = (flakes.${module.commit}).modules.${module-id};
      in
      # verify the outpath matches what the lockfile expects
      assert m.outPath == module.path;
      mkPhonyOCI { module = m; moduleId = name; })
    modulesLocks;

in

pkgs.linkFarm "nixmodules-phonyOCI-${revstring}" (
  mapAttrsToList (name: value: { inherit name; path = value; }) phonyOCIs
)
