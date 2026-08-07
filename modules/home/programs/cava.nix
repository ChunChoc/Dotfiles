{ ... }:

{
  # --------------------------------------------------------
  # cava (visualizador de audio en terminal)
  # --------------------------------------------------------
  # cava ya estaba en el sistema, pero llegaba implícito como dependencia de
  # DankMaterialShell y sin configurar. Aquí queda declarado y con tema propio.
  #
  # Esto NO afecta al visualizador de la barra de DMS: DMS escribe su propio
  # config temporal (/tmp/dms-cava-*.conf, con method=raw) y lanza `cava -p`
  # contra él. Este archivo es solo para el cava que corres en una terminal.
  programs.cava = {
    enable = true;
    settings = {
      general = {
        framerate = 60;
        autosens = 1;
        bar_width = 2;
        bar_spacing = 1;
      };

      # Captura del monitor del sink por defecto: visualiza lo que esté sonando,
      # venga de MPD, del navegador o de donde sea, y sigue el cambio de salida
      # cuando enchufas audífonos.
      input = {
        method = "pipewire";
        source = "auto";
      };

      output = {
        channels = "stereo";
        mono_option = "average";
      };

      # Degradado Catppuccin Mocha recorriendo el círculo de tono: cian -> azul
      # -> violeta -> magenta -> rojo -> naranja. El mauve del sistema queda en
      # el centro, que es donde más tiempo pasan las barras.
      # gradient_color_1 es la base. Van entre comillas simples: cava las exige.
      color = {
        background = "'default'"; # hereda el fondo del terminal
        gradient = 1;
        gradient_count = 8;
        gradient_color_1 = "'#94e2d5'"; # teal
        gradient_color_2 = "'#89b4fa'"; # blue
        gradient_color_3 = "'#b4befe'"; # lavender
        gradient_color_4 = "'#cba6f7'"; # mauve  <- el acento del sistema
        gradient_color_5 = "'#f5c2e7'"; # pink
        gradient_color_6 = "'#eba0ac'"; # maroon
        gradient_color_7 = "'#fab387'"; # peach
        gradient_color_8 = "'#f9e2af'"; # yellow
      };

      smoothing = {
        # monstercat suaviza entre barras vecinas: en vez de columnas sueltas
        # saltando, el espectro se mueve como una onda continua.
        monstercat = 1;
        waves = 0;
        noise_reduction = 65;
      };
    };
  };
}
