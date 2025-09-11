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
    checkinterval=3600,
    cross_config=None,
):
    inputs = {
        "nix-ros-hydra": {
            "type": "git",
            "value": "https://github.com/wentasah/nix-ros-hydra main",
            "emailresponsible": False
        },
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
    if cross_config is not None:
        inputs.update({
            "crossSystem": {
                "type": "nix",
                "value": cross_config,
                "emailresponsible": False
            },
        })
    return {
        "enabled": 1,
        "hidden": False,
        "description": "",
        "nixexprinput": "nix-ros-hydra",
        "nixexprpath": "release.nix",
        "checkinterval": checkinterval,
        "schedulingshares": schedulingshares,
        "enableemail": False,
        "enable_dynamic_run_command": False,
        "emailoverride": "",
        "keepnr": keepnr,
        "inputs": inputs
    }


def generate_nix_ros_overlay(jobsets, owner):
    for job_type in ['master', 'develop', 'unstable']:
        for system in ['x86_64-linux', 'aarch64-linux']:
            for distro in ['.top', '.examples', '.all', 'noetic', 'humble', 'jazzy', 'kilted', 'rolling']:
                # Set job defaults
                branch = job_type
                nixpkgs_branch = None
                schedulingshares = 100
                keepnr = 20
                checkinterval = 3600

                # Override job parameters
                if job_type == 'unstable':
                    branch = "develop"
                    nixpkgs_branch = "nixos-unstable"
                    schedulingshares = 30
                    keepnr = 5
                if job_type == 'develop':
                    checkinterval = 300

                jobsets[f"{job_type}-{distro.strip('.')}-{system.split('-')[0]}"] = (
                    template(
                        owner,
                        branch,
                        system,
                        distro if distro != ".all" else None,
                        nixpkgs_branch,
                        schedulingshares=schedulingshares,
                        keepnr=keepnr,
                        checkinterval=checkinterval,
                    )
                )

def generate_experiments(jobsets):
    for owner, branch in [
            ("lopsided98", "develop"),
            ("lopsided98", "master"),
            ("wentasah", "ament-vendor-auto-update"),
            ("wentasah", "develop"),
            ("wentasah", "master"),
            ("wentasah", "test"),
    ]:
        jobsets[f"{owner}-{branch}"] = template(
            owner,
            branch,
            system="x86_64-linux",
            distro=None,
            schedulingshares=50,
            keepnr=1,
        )
    jobsets["lopsided98-develop-stable"] = template(
        "lopsided98",
        "develop",
        nixpkgs_branch="nixos-25.05",
        system="x86_64-linux",
        distro=None,
        schedulingshares=50,
        keepnr=1,
        checkinterval=86400,
    )
    jobsets["lopsided98-noetic-stable"] = template(
        "lopsided98",
        "develop",
        nixpkgs_branch="nixos-25.05",
        system="x86_64-linux",
        distro="noetic",
        schedulingshares=50,
        keepnr=1,
    )
    jobsets["lopsided98-develop-cross"] = template(
        "lopsided98",
        "develop",
        system="x86_64-linux",
        distro=None,
        schedulingshares=50,
        keepnr=1,
        cross_config='{ config = "aarch64-unknown-linux-gnu"; }',
        checkinterval=86400,
    )


jobsets = {}

match sys.argv[1]:
    case "nix_ros_overlay": generate_nix_ros_overlay(jobsets, "lopsided98")
    case "nix_ros_overlay_wentasah": generate_nix_ros_overlay(jobsets, "wentasah")
    case "nix_ros_experiments": generate_experiments(jobsets)

print(json.dumps(jobsets, indent=2))
