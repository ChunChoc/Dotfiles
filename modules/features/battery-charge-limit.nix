{ config, lib, pkgs, ... }:
let
  limit = config.myFeatures.batteryChargeLimit;
in
{
  config = lib.mkIf (limit != null) {
    # Aplica el umbral de carga a todas las baterías compatibles al arrancar.
    # No usa TLP a propósito: TLP reemplaza a power-profiles-daemon y rompería
    # los power plans. Esto solo escribe el sysfs del umbral, sin tocar PPD.
    systemd.services.battery-charge-limit = {
      description = "Limita la carga de batería al ${toString limit}%";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        for bat in /sys/class/power_supply/BAT*; do
          f="$bat/charge_control_end_threshold"
          [ -w "$f" ] && echo ${toString limit} > "$f"
        done
      '';
    };

    # Reaplica al insertar/cambiar batería (la extraíble resetea su umbral
    # al sacarla y volverla a poner).
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="power_supply", KERNEL=="BAT*", RUN+="${pkgs.bash}/bin/sh -c 'echo ${toString limit} > /sys/class/power_supply/%k/charge_control_end_threshold'"
    '';
  };
}
