# NixOS module: periodically generate shields.io endpoint badges describing
# the date of the nixpkgs input pinned by nix-ros-overlay.
#
# Enable with:
#   imports = [ ./nixpkgs-date-badge.nix ];
#   services.nixpkgs-date-badge.enable = true;
#
# Badge JSON files are written to
#   <stateDir>/www/nixpkgs-date-<branch>.json
# for each configured branch (master and develop by default).

{ config, lib, pkgs, ... }:

let
  cfg = config.services.nixpkgs-date-badge;

  # The badge generator itself, wrapped with its runtime dependencies.
  badgeScript = pkgs.writeShellApplication {
    name = "nixpkgs-date-badge";
    runtimeInputs = with pkgs; [ git jq coreutils ];
    text = builtins.readFile ./nixpkgs-date-badge.sh;
  };

  # Runner that generates a badge for every requested branch, reusing a single
  # shared checkout of the overlay.
  runner = pkgs.writeShellApplication {
    name = "nixpkgs-date-badge-all";
    runtimeInputs = [ badgeScript ];
    text = ''
      for branch in "$@"; do
          BRANCH="$branch" \
          REPO_DIR="${cfg.stateDir}/nix-ros-overlay" \
          OUT="${cfg.stateDir}/www/nixpkgs-date-$branch.json" \
          nixpkgs-date-badge
      done
    '';
  };
in
{
  options.services.nixpkgs-date-badge = {
    enable = lib.mkEnableOption "periodic nix-ros-overlay nixpkgs date badge generation";

    branches = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "master" "develop" ];
      description = "nix-ros-overlay branches to generate badges for.";
    };

    stateDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/nixpkgs-date-badge";
      description = ''
        Directory holding the nix-ros-overlay checkout. Generated badge JSON
        files are written to the <literal>www</literal> subdirectory, suitable
        for serving by a web server.
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "nixpkgs-date-badge";
      description = "User account under which the badge generator runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "nixpkgs-date-badge";
      description = "Group under which the badge generator runs.";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "hourly";
      description = "systemd OnCalendar expression controlling how often badges are regenerated.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users = lib.mkIf (cfg.user == "nixpkgs-date-badge") {
      nixpkgs-date-badge = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.stateDir;
      };
    };

    users.groups = lib.mkIf (cfg.group == "nixpkgs-date-badge") {
      nixpkgs-date-badge = { };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0755 ${cfg.user} ${cfg.group} - -"
      "d ${cfg.stateDir}/www 0755 ${cfg.user} ${cfg.group} - -"
    ];

    systemd.services.nixpkgs-date-badge = {
      description = "Generate nix-ros-overlay nixpkgs date badges";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.stateDir;
        ExecStart = "${runner}/bin/nixpkgs-date-badge-all ${lib.escapeShellArgs cfg.branches}";
      };
    };

    systemd.timers.nixpkgs-date-badge = {
      description = "Regenerate nix-ros-overlay nixpkgs date badges periodically";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.interval;
        Persistent = true;
      };
    };
  };
}
