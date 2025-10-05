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
      # Allow building gz-sim-vendor and related packages by hydra.
      # Without this, we get eval failures and don't know about other
      # errors. Users then complain about them.
      permittedInsecurePackages = [
        "freeimage-unstable-2021-11-01"
        "freeimage-3.18.0-unstable-2024-04-18"
      ];
    };
  };
  inherit (pkgs.lib) isDerivation filterAttrs nameValuePair;
  inherit (builtins) mapAttrs attrNames filter listToAttrs readDir;
  genAttrs' = xs: f: listToAttrs (map f xs); # TODO remove after we're at newer nixpkgs
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
  releaseRosPackages = mapAttrs cleanupDistro pkgs.rosPackages;
  overlayAttrNames = attrNames ((import "${nix-ros-overlay}/overlay.nix") null pkgs);
  toplevelPackagesEntries =
    map (name: { inherit name; value = pkgs.${name} or null; })
      overlayAttrNames;
  validToplevelPackageEntries = filter (e: isDerivation e.value)
    toplevelPackagesEntries;
  toplevelPackages = listToAttrs validToplevelPackageEntries;
  exampleRos2GzForDistro = rosDistro: nameValuePair "ros2-gz-${rosDistro}" (
    import ("${nix-ros-overlay}/examples/ros2-gz.nix") { inherit pkgs rosDistro; }
  );
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
    // genAttrs' [ "jazzy" "kilted" "rolling" ] exampleRos2GzForDistro;
  };
in
if distro == ".top" then toplevelPackages
else if distro == ".examples" then releasePackages.examples
else if distro == null then releasePackages
else releasePackages.rosPackages.${distro}
