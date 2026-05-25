let
  nix-ros-overlay-lock = nix-ros-overlay: builtins.fromJSON (builtins.readFile "${nix-ros-overlay}/flake.lock");
  lockedNixpkgs = nix-ros-overlay:
    let lock = nix-ros-overlay-lock nix-ros-overlay; in
    fetchTarball {
      url = "https://github.com/lopsided98/nixpkgs/archive/${lock.nodes.nixpkgs.locked.rev}.tar.gz";
      sha256 = lock.nodes.nixpkgs.locked.narHash;
    };
in
{
  nix-ros-overlay,
  nixpkgs ? lockedNixpkgs nix-ros-overlay,
  distro ? null, # what to build: null = everything, .* = top or examples, anything else = specific ROS distro
  system ? builtins.currentSystem,
  crossSystem ? { system = system; }, # no cross compilation by default
}:
let
  pkgs = import nix-ros-overlay {
    inherit nixpkgs system crossSystem;
    config = {
      permittedInsecurePackages = [ ];
    };
  };
  inherit (pkgs.lib) isDerivation filterAttrs nameValuePair flatten genAttrs';
  inherit (builtins) mapAttrs attrNames filter listToAttrs readDir;
  cleanupDistro = (_: a: removeAttrs a [
    "lib"
    "python"
    "python3"
    "python2"
    "pythonPackages"
    "python2Packages"
    "python3Packages"
    "boost"
  ]);
  rosDistros = filterAttrs (n: v: builtins.isAttrs v) pkgs.rosPackages;
  releaseRosPackages = mapAttrs cleanupDistro rosDistros;
  overlayAttrNames = attrNames ((import "${nix-ros-overlay}/overlay.nix") null pkgs);
  toplevelPackagesEntries =
    map (name: { inherit name; value = pkgs.${name} or null; })
      overlayAttrNames;
  validToplevelPackageEntries = filter (e: isDerivation e.value)
    toplevelPackagesEntries;
  pythonPackageNames = flatten (map (f: attrNames (f null null)) pkgs.pythonPackagesExtensions);
  pythonPackagesEntries = (
    map (name: {
      inherit name;
      value = pkgs.python3Packages.${name} or null;
    }) pythonPackageNames
  );
  toplevelPackages = listToAttrs validToplevelPackageEntries // {
    python3Packages = listToAttrs pythonPackagesEntries;
  };
  exampleForDistro = exampleName: rosDistro:
    nameValuePair "${exampleName}-${rosDistro}" (
      import "${nix-ros-overlay}/examples/${exampleName}.nix" { inherit pkgs rosDistro; }
    );
  inherit (pkgs.rosPackages.lib) distroNames;
  releasePackages = toplevelPackages // {
    rosPackages = removeAttrs releaseRosPackages [
      "lib"
      "mkRosDistroOverlay"
      "foxy" # No CI for EOL distro
      "iron" # No CI for EOL distro
    ];
    examples = (mapAttrs
      (file: _: import ("${nix-ros-overlay}/examples/${file}") { inherit pkgs; })
      (filterAttrs (n: v: v == "regular")
        (readDir "${nix-ros-overlay}/examples")))
    // (genAttrs' [ "jazzy" "kilted" "lyrical" "rolling" ] (exampleForDistro "ros2-gz"))
    // (genAttrs' distroNames (exampleForDistro "ros2-gz"))
    // (genAttrs' distroNames (exampleForDistro "ros2-basic"))
    // (genAttrs' distroNames (exampleForDistro "ros2-desktop"))
    // (genAttrs' distroNames (exampleForDistro "ros2-desktop-full"))
    ;
  };
in
if distro == ".top" then toplevelPackages
else if distro == ".examples" then releasePackages.examples
else if distro == null then releasePackages
else releasePackages.rosPackages.${distro}
