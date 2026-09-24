{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      corefonts
      vista-fonts
      liberation_ttf
      liberation-sans-narrow
      nerd-fonts.jetbrains-mono
      # Tipografía de la interfaz de DankMaterialShell. Es la fuente de
      # Material 3: la variable de Roboto, con los ejes (peso, ancho, grado
      # óptico) que la spec Expressive usa para dar contraste entre los tamaños
      # display y los de texto. DMS trae Inter empaquetada como asset, pero
      # "Roboto Flex" tiene que estar instalada a nivel de sistema para que Qt
      # la resuelva; si no, cae de vuelta a la fuente por defecto sin avisar.
      roboto-flex
    ];

    fontconfig = {
      enable = true;
      # Sin esto los genéricos caen en DejaVu: Electron (Obsidian), el
      # contenido web, Zed y cualquier app sin fuente propia salían en DejaVu
      # Sans mientras DMS y GTK usaban Roboto Flex. La mono es la de Ghostty.
      #
      # La fuente del Pixel (Android 16, M3 Expressive) es Google Sans Flex,
      # libre (OFL) y en google/fonts desde el 2026-09-04. Cuando el snapshot
      # de `google-fonts` en nixpkgs sea posterior a esa fecha (hoy es del
      # 2026-03-13), se instala con `google-fonts.override { fonts = [
      # "GoogleSansFlex" ]; }` y se cambia aquí, en theme.nix (gtk.font) y en
      # el `fontFamily` de DMS.
      defaultFonts = {
        sansSerif = [ "Roboto Flex" ];
        monospace = [ "JetBrainsMono Nerd Font" ];
      };
    };
  };
}
