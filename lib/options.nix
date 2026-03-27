{ config, lib, ... }:

{
  options.myFeatures = {
    development = lib.mkEnableOption "herramientas de desarrollo y programación";
    gaming = lib.mkEnableOption "juegos, Steam y soporte 32-bit";
    virtualization = lib.mkEnableOption "máquinas virtuales con KVM/QEMU";
    localsend = lib.mkEnableOption "LocalSend (abrir puertos firewall)";
  };
}
