#!/usr/bin/env python3

import json


def template(branch, system, toplevelOnly=False, distro=None, nixpkgs_branch=None):
    inputs = {
        "nix-ros-overlay": {
            "type": "git",
            "value": f"https://github.com/wentasah/nix-ros-overlay {branch}",
            "emailresponsible": False
        },
        "system": {
            "type": "string",
            "value": system,
            "emailresponsible": False
        },
        "distro": {
            "type": "string",
            "value": distro,
            "emailresponsible": False
        },
    }
    if nixpkgs_branch is not None:
        inputs.update({
            "nixpkgs": {
                "type": "git",
                "value": f"https://github.com/NixOS/nixpkgs {nixpkgs_branch}",
                "emailresponsible": False
            },
        })
    return {
        "enabled": 1,
        "hidden": False,
        "description": "",
        "nixexprinput": "nix-ros-overlay",
        "nixexprpath": "release.nix",
        "checkinterval": 3600,
        "schedulingshares": 100,
        "enableemail": False,
        "enable_dynamic_run_command": False,
        "emailoverride": "",
        "keepnr": 20,
        "inputs": inputs
    }


jobsets = {}

for job_type in ['master', 'develop', 'unstable']:
    for system in ['x86_64-linux', 'aarch64-linux']:
        for distro in ['.top', '.examples', 'noetic', 'humble', 'iron', 'jazzy', 'rolling']:
            if job_type == 'unstable':
                branch = "develop"
                nixpkgs_branch = "nixos-unstable"
            else:
                branch = job_type
                nixpkgs_branch = None
            jobsets[f"{job_type}-{distro.strip('.')}-{system.split('-')[0]}"] = (
                template(branch, system, False, distro, nixpkgs_branch)
            )

print(json.dumps(jobsets, indent=2))
