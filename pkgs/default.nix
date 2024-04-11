{ pkgs, self }:

with pkgs.lib;

let
  modules = self.modules;
  revstring_long = self.rev or "dirty";
  revstring = builtins.substring 0 7 revstring_long;
  all-modules = builtins.fromJSON (builtins.readFile ../modules.json);

  upgrade-maps = import ./upgrade-maps {
    inherit pkgs;
  };

  mkPhonyOCI = pkgs.callPackage ./mk-phony-oci { ztoc-rs = self.inputs.ztoc-rs.packages.x86_64-linux.default; };

  mkPhonyOCIs = { moduleIds ? null }: pkgs.callPackage ./mk-phony-ocis {
    inherit mkPhonyOCI revstring;
    modulesLocks = import ./filter-modules-locks {
      inherit pkgs moduleIds;
    };
  };

  bundle-squashfs-fn = { moduleIds ? null, diskName ? "disk.raw" }:
    let
      modulesLocks = import ./filter-modules-locks {
        inherit pkgs upgrade-maps;
        inherit moduleIds;
      };
    in
    pkgs.callPackage ./bundle-image {
      bundle-locked = bundle-locked-fn {
        inherit modulesLocks;
      };
      inherit revstring diskName;
    };

in
rec {
  inherit upgrade-maps;

  default = moduleit;
  moduleit = pkgs.callPackage ./moduleit { };

  bundle = pkgs.linkFarm "nixmodules-bundle-${revstring}" (
    mapAttrsToList (name: value: { inherit name; path = value; }) modules
  );

  modulesMap = modules: mapAttrs (name: drv: {
      commit = revstring_long;
      path = drv.outPath;
    }) modules;

  modulesLocksJSON = modules: pkgs.writeTextFile {
    name = "modules.json";
    text = builtins.toJSON (modulesMap modules);
  };

  bundle-fn = modules: pkgs.linkFarm "nixmodules-bundle" ([
    {
      name = "etc/nixmodules/modules.json";
      path = modulesLocksJSON modules;
    }
    {
      name = "etc/nixmodules/registry.json";
      path = pkgs.callPackage ./registry {
        modulesMap = (modulesMap modules);
        inherit self;
      };
    }
  ] ++ (mapAttrsToList (name: value: { inherit name; path = value; }) modules));

  testModules = filterAttrs (name: _: name == "python-3.10" || name == "nodejs-20") modules;

  custom-bundle = bundle-fn testModules;

  test-registry = pkgs.callPackage ./registry {
    modulesMap = (modulesMap testModules);
    inherit self;
  };

  rev = pkgs.writeText "rev" revstring;

  rev_long = pkgs.writeText "rev_long" revstring_long;

  bundle-image = bundle-squashfs-fn { };

  bundle-image-tarball = pkgs.callPackage ./bundle-image-tarball { inherit bundle-image revstring; };

  bundle-squashfs = bundle-squashfs-fn {
    moduleIds = [ "python-3.10" "nodejs-18" "nodejs-20" "docker" "replit" ];
    diskName = "disk.sqsh";
  };

  custom-bundle-squashfs = bundle-squashfs-fn {
    # customize these IDs for dev. They can be like "python-3.10:v10-20230711-6807d41" or "python-3.10"
    # publish your feature branch first and make sure modules.json is current, then
    # in goval dir (next to nixmodules), run `make custom-nixmodules-disk` to use this disk in conman
    # There is no need to check in changes to this.
    moduleIds = [ "python-3.10" "nodejs-18" "nodejs-20" "docker" "replit" ];
    diskName = "disk.sqsh";
  };

  custom-bundle-phony-ocis = mkPhonyOCIs { moduleIds = [ "nodejs-18" "nodejs-20" ]; };

  all-phony-oci-bundles = mapAttrs
    (moduleId: module:
      let
        flake = builtins.getFlake "github:replit/nixmodules/${module.commit}";
        shortModuleId = elemAt (strings.splitString ":" moduleId) 0;
      in
      mkPhonyOCI {
        inherit moduleId;
        module = flake.deploymentModules.${shortModuleId};
      })
    all-modules;

  bundle-phony-ocis = mkPhonyOCIs { };

  inherit all-modules;

  deploymentModules = self.deploymentModules;

} // modules
