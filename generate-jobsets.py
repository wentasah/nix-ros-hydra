#!/usr/bin/env python3

import json


def template(branch, system, toplevelOnly=False, distro=None):
    return {
        "enabled": 1,
        "hidden": False,
        "description": "",
        "nixexprinput": "nix-ros-overlay",
        "nixexprpath": "release.nix",
        "checkinterval": 300,
        "schedulingshares": 100,
        "enableemail": False,
        "enable_dynamic_run_command": False,
        "emailoverride": "",
        "keepnr": 20,
        "inputs": {
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
    }


jobsets = {}

for branch in ['master', 'develop']:
    for system in ['x86_64-linux', 'aarch64-linux']:
        for distro in ['.top', '.examples', 'noetic', 'humble', 'iron', 'jazzy', 'rolling']:
            jobsets[f"{branch}-{distro.strip('.')}-{system.split('-')[0]}"] = template(branch, system, False, distro)

print(json.dumps(jobsets, indent=2))
