inputs: {
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption;

  inherit (lib) types mkIf optional;
  cfg = config.programs.discaml;
in {
  options.programs.discaml = {
    enable = mkEnableOption "discaml";
    package = mkOption {
      type = types.package;
      default = inputs.self.packages.x86_64-linux.default;
    };

    socketPath = mkOption {
      type = types.str;
      description = "discord rpc socket (make shure to use nix store paths)";
      default = let
        ss = lib.getExe' pkgs.iproute2 "ss";
        grep = lib.getExe' pkgs.gnugrep "grep";
        head = lib.getExe' pkgs.coreutils "head";
      in "$(${ss} -lx | ${grep} -o '[^ ]*discord[^ ]*' | ${head} -n 1)";
      example = "/run/user/1000/discord-ipc-0";
    };

    clientId = mkOption {
      type = types.nullOr types.int;
      description = "discord client id `https://discord.com/developers/applications/`";
      default = null;
    };

    scriptPath = mkOption {
      type = types.nullOr types.str;
      description = "script to update activity, see --help for output format. make sure to nixify script";
      default = null;
    };

    tick = mkOption {
      type = types.nullOr types.int;
      description = "time in seconds between updates";
      default = null;
    };

    activity = {
      name = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      details = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      state = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      type = mkOption {
        type = types.nullOr types.int;
        default = null;
      };
      started = mkOption {
        type = types.nullOr types.int;
        default = null;
      };
      image = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages =
      optional (cfg.package != null) cfg.package;

    systemd.user.services.discaml = {
      Unit = {
        Description = "discaml: discord rich presence terminal client";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = let
        op = arg: val:
          if val != null
          then
            " "
            + arg
            + " "
            + (
              if builtins.isString val
              then ''"${val}"''
              # probably int
              else toString val
            )
          else "";
      in {
        ExecStart =
          "${lib.getExe pkgs.bash} -c '${cfg.package}/bin/discaml"
          + builtins.replaceStrings ["'"] ["\\'"]
          (
            op "-sock" cfg.socketPath
            + op "-id" cfg.clientId
            + op "-n" cfg.activity.name
            + op "-d" cfg.activity.details
            + op "-s" cfg.activity.state
            + op "-t" cfg.activity.type
            + op "-start" cfg.activity.started
            + op "-image" cfg.activity.image
            + op "-tick" cfg.tick
            + op "-script" cfg.scriptPath
          )
          + "'";
        Restart = "on-failure";
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
