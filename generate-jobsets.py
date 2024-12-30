#!/usr/bin/env python3

import json
import sys

def template(
    owner,
    branch,
    system,
    distro=None,
    nixpkgs_branch=None,
    schedulingshares=100,
    keepnr=20,
):
    inputs = {
        "nix-ros-overlay": {
            "type": "git",
            "value": f"https://github.com/{owner}/nix-ros-overlay {branch}",
            "emailresponsible": False
        },
        "system": {
            "type": "string",
            "value": system,
            "emailresponsible": False
        },
    }
    if distro is not None:
        inputs.update({
            "distro": {
                "type": "string",
                "value": distro,
                "emailresponsible": False
            },
        })
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
        "schedulingshares": schedulingshares,
        "enableemail": False,
        "enable_dynamic_run_command": False,
        "emailoverride": "",
        "keepnr": keepnr,
        "inputs": inputs
    }


def generate_nix_ros_overlay(jobsets):
    for job_type in ['master', 'develop', 'unstable', 'wsh-test']:
        for system in ['x86_64-linux', 'aarch64-linux']:
            for distro in ['.top', '.examples', '.all', 'noetic', 'humble', 'iron', 'jazzy', 'rolling']:
                # Set job defaults
                owner = 'lopsided98'
                branch = job_type
                nixpkgs_branch = None
                schedulingshares = 100
                keepnr = 20

                # Override job parameters
                if branch == 'master':
                    owner = "wentasah"  # my release.nix changes are not yet in master
                if job_type == 'unstable':
                    branch = "develop"
                    nixpkgs_branch = "nixos-unstable"
                    schedulingshares = 30
                    keepnr = 5
                elif job_type == 'wsh-test':
                    owner = "wentasah"
                    branch = "test"
                    keepnr = 1

                jobsets[f"{job_type}-{distro.strip('.')}-{system.split('-')[0]}"] = (
                    template(
                        owner,
                        branch,
                        system,
                        distro if distro != ".all" else None,
                        nixpkgs_branch,
                        schedulingshares=schedulingshares,
                        keepnr=keepnr
                    )
                )

def generate_experiments(jobsets):
    for owner, branch in [
            ("lopsided98", "develop"),
            ("wentasah", "finalAttrs")
    ]:
        jobsets[f"{owner}-{branch}"] = template(
            owner,
            branch,
            system="x86_64-linux",
            distro=None,
            schedulingshares=50,
            keepnr=1,
        )


jobsets = {}

match sys.argv[1]:
    case "nix_ros_overlay": generate_nix_ros_overlay(jobsets)
    case "nix_ros_experiments": generate_experiments(jobsets)

print(json.dumps(jobsets, indent=2))
