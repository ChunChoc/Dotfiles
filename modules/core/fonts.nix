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

    fontconfig.enable = true;
  };
}
