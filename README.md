# Hydra jobsets configuration for nix-ros-overlay

This repository contains definitions of [hydra jobsets][] for
[nix-ros-overlay][].

The jobsets are named as `type-pkgset-arch`, where:

`type` is one of:

- `master`: `master` branch of nix-ros-overlay. This branch is
  typically some commits behind `develop` and represents what users
  should use.
- `develop`: `develop` branch of nix-ros-overlay built against a
  pinned version of nixpkgs.
- `unstable`: `develop` branch of nix-ros-overlay built against
  `nixos-unstable` branch of nixpkgs.

`pkgset` is:

- a ROS distro such as `jazzy` or `rolling`, or
- `top`: representing top-level packages (not part of any distro) such
  as `colcon`, `bloom`, etc.
- `examples`: examples from the `examples` subdirectory.

[hydra jobsets]: https://hydra.iid.ciirc.cvut.cz/project/nix-ros-overlay
[nix-ros-overlay]: https://github.com/lopsided98/nix-ros-overlay
