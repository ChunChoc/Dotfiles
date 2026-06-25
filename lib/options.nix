{ config, lib, ... }:

{
  options.myFeatures = {
    development = lib.mkEnableOption "herramientas de desarrollo y programación";
    gaming = lib.mkEnableOption "juegos, Steam y soporte 32-bit";
    communication = lib.mkEnableOption "apps de comunicación y mensajería";
    office = lib.mkEnableOption "apps de oficina y documentos";
    virtualization = lib.mkEnableOption "máquinas virtuales con KVM/QEMU";
    localsend = lib.mkEnableOption "LocalSend (abrir puertos firewall)";

    batteryChargeLimit = lib.mkOption {
      type = lib.types.nullOr (lib.types.ints.between 1 100);
      default = null;
      example = 90;
      description = "Límite de carga de batería en % (null = sin límite). "
        + "Aplica a todas las baterías que soporten charge_control_end_threshold.";
    };
  };
}
