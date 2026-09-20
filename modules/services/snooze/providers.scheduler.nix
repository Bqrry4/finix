{ config, lib, ... }:
{
  options.providers.scheduler = {
    backend = lib.mkOption {
      type = lib.types.enum [ "snooze" ];
    };
  };

  config = lib.mkIf (config.providers.scheduler.backend == "snooze") {
    providers.scheduler.supportedFeatures = {
      user = true;
    };

    services.snooze.tasks = lib.mapAttrs (
      name: task:
      let
        intervals = lib.splitString " " task.interval;
        isCronFmt = builtins.length intervals == 5;
      in
      {
        user = task.user;
        command = task.command;
        schedule =
          with builtins;
          if !isCronFmt then
            { }
          else
            let
              months = [
                "jan"
                "feb"
                "mar"
                "apr"
                "may"
                "jun"
                "jul"
                "aug"
                "sep"
                "oct"
                "nov"
                "dec"
              ];
              weekdays = [
                "mon"
                "tue"
                "wed"
                "thu"
                "fri"
                "sat"
                "sun"
              ];

              # Cron format supports names for the `month` and `weekday`, convert them to ordinal for `snooze`.
              replaceNames =
                value: names:
                replaceStrings names (map toString (builtins.genList (i: i + 1) (length names))) (
                  lib.toLower value
                );
              month = replaceNames (elemAt intervals 3) months;
              weekday = replaceNames (elemAt intervals 4) weekdays;
            in
            {
              minute = elemAt intervals 0;
              hour = elemAt intervals 1;
              day = elemAt intervals 2;
              inherit month weekday;
            };
      }
    ) config.providers.scheduler.tasks;
  };
}
