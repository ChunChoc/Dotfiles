{ config, pkgs, ... }:

let
  # El tema de Catppuccin trae `syntect_theme` apuntando a una ruta de ejemplo
  # bajo ~/.config. Aquí se reescribe al .tmTheme real, que ya está pineado en
  # programs/bat.nix (repo catppuccin/bat): así el resaltado de sintaxis del
  # panel de vista previa de Yazi y el de `bat` salen del mismo archivo y no hay
  # dos pines del mismo repo que se puedan desincronizar.
  #
  # Si algún día se quita bat, esto falla en la evaluación con un error claro;
  # la solución sería mover el fetchFromGitHub aquí.
  batTheme = config.programs.bat.themes."Catppuccin Mocha";
  syntectTheme = "${batTheme.src}/${batTheme.file}";

  catppuccinMauve = builtins.fromTOML (builtins.readFile ../dotfiles/yazi/theme.toml);
in

{
  # --------------------------------------------------------
  # Yazi — gestor de archivos (TUI)
  # --------------------------------------------------------
  # Sustituye a Nautilus. El motivo no es solo el peso: Nautilus es GTK4 +
  # libadwaita y su primer arranque de la sesión costaba ~2 s (leer del disco
  # ~1300 .so y el árbol de fuentes; las siguientes eran instantáneas solo por
  # el page cache del kernel). Evitarlo obligaba a dejarlo residente ~150 MB.
  # Yazi corre dentro de Ghostty, que ya está precargado por su unit de systemd
  # (ver ghostty.nix), así que abre en milisegundos sin residente propio.
  #
  # Lo que se pierde con este cambio es gvfs: montar USBs al enchufarlos,
  # papelera y rutas de red (smb://, sftp://). Se hace a mano con `udisksctl`.
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;

    # Envoltorio del shell que hace `cd` a donde dejaste el cursor al salir.
    # Se declara explícito porque el valor por defecto depende de stateVersion
    # (era "yy" antes de 26.05, "y" después) y así no cambia solo en un bump.
    shellWrapperName = "y";

    # Dependencias de las vistas previas. Van en el wrapper de Yazi en vez de en
    # home.packages para no ensuciar el PATH global con cosas que solo usa él.
    extraPackages = with pkgs; [
      file # detección de tipo MIME; Yazi la invoca por cada archivo
      ffmpeg # miniaturas de vídeo (ffprobe + extracción de fotograma)
      poppler-utils # pdftoppm, para previsualizar PDF
      imagemagick # formatos de imagen que Yazi no decodifica por su cuenta
      resvg # SVG rasterizado
      p7zip # listar el contenido de zip/7z/rar sin extraerlos
      jq # formatear JSON en la vista previa
      ripgrep # búsqueda por contenido (tecla `s`)
      fd # búsqueda por nombre (tecla `S`); ya está en packages.nix, pero
      # declararlo aquí hace que Yazi funcione aunque se quite de allí
    ];

    settings = {
      mgr = {
        # Tres paneles: padre estrecho, actual, vista previa ancha.
        ratio = [
          1
          3
          4
        ];
        sort_by = "natural"; # "archivo10" va después de "archivo9", no antes
        sort_dir_first = true;
        show_hidden = false; # se alterna en caliente con `.`
        linemode = "size";
      };

      preview = {
        max_width = 1000;
        max_height = 1000;
      };
    };

    # Bordes redondeados en los tres paneles, para que case con el radio 12 de
    # las cápsulas de DMS y de las ventanas de niri.
    plugins = {
      full-border = pkgs.yaziPlugins.full-border;
    };

    # El `type` tiene que ser la expresión Lua `ui.Border.ROUNDED`, no una
    # cadena, así que el setup va aquí y no en `plugins.<n>.settings` (que
    # serializaría el valor entre comillas y Yazi lo rechazaría).
    initLua = ''
      require("full-border"):setup({ type = ui.Border.ROUNDED })
    '';

    # El tema vendorizado, con la ruta del .tmTheme resuelta al store.
    theme = catppuccinMauve // {
      mgr = catppuccinMauve.mgr // {
        syntect_theme = syntectTheme;
      };
    };
  };

  # Handler de `inode/directory`: lo que se abre al pulsar una carpeta desde
  # otra aplicación (una descarga de Brave, "abrir carpeta contenedora", etc.).
  #
  # `ghostty +new-window` es la clave y es lo que le faltaba al intento con
  # Nautilus: habla por D-Bus con el proceso ya residente en vez de arrancar uno
  # nuevo. Medido en esta máquina: 80-160 ms. La página de manual lo documenta
  # justo para esto ("suitable for binding to keys in your window manager") y
  # además activa Ghostty por D-Bus si no estuviera corriendo, así que nunca
  # deja de funcionar.
  #
  # `--class` existe, pero abriría una *instancia aparte* de Ghostty y pagaría
  # el arranque completo, así que la ventana se identifica por el título.
  xdg.desktopEntries.yazi = {
    name = "Yazi";
    genericName = "Gestor de archivos";
    comment = "Explorar archivos en la terminal";
    exec = "${config.programs.ghostty.package}/bin/ghostty +new-window --title=Yazi -e yazi %f";
    icon = "system-file-manager";
    terminal = false;
    categories = [
      "System"
      "Utility"
      "FileTools"
      "FileManager"
    ];
    mimeType = [ "inode/directory" ];
  };
}
