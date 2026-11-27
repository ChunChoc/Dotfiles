{ lib, ... }:

let
  settings = {
    general = {
      framerate = 60;
      autosens = 1;
      bar_width = 2;
      bar_spacing = 1;
    };

    # Captura el monitor del sink por defecto y sigue los cambios de salida.
    input = {
      method = "pipewire";
      source = "auto";
    };

    output = {
      channels = "stereo";
      mono_option = "average";
    };

    smoothing = {
      # monstercat suaviza el espectro entre barras vecinas.
      monstercat = 1;
      waves = 0;
      noise_reduction = 65;
    };
  };
in
{
  programs.cava.enable = true;

  # Para cava en terminal. DMS pasa su propio config a cava -p para la barra.
  xdg.configFile."cava/base.conf".text = lib.generators.toINI { } settings;
}
