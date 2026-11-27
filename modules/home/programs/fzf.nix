{ ... }:

{
  # Colores de la terminal (la paleta ANSI de DMS), también en Fish.
  # La integración con Fish (ctrl-t archivos, ctrl-r historial) es automática.
  programs.fzf = {
    enable = true;
    defaultOptions = [ "--color=base16" ];
    colors = {
      bg = "-1";
      fg = "-1";
      "fg+" = "-1:reverse";
      "bg+" = "-1";
      hl = "1";
      "hl+" = "1:bold:reverse";
      header = "1";
      info = "6";
      prompt = "6";
      pointer = "4";
      spinner = "4";
      marker = "4";
      border = "8";
      label = "-1";
    };
  };
}
