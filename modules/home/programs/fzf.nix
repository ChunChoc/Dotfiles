{ ... }:

{
  # fzf con paleta Catppuccin Mocha (los colores van en FZF_DEFAULT_OPTS,
  # así aplican a fzf suelto y a las funciones ff/vf/bf/cf de fish).
  # La integración con Fish (ctrl-t archivos, ctrl-r historial) es automática.
  programs.fzf = {
    enable = true;
    colors = {
      bg = "#1e1e2e";
      "bg+" = "#313244";
      fg = "#cdd6f4";
      "fg+" = "#cdd6f4";
      hl = "#f38ba8";
      "hl+" = "#f38ba8";
      header = "#f38ba8";
      info = "#cba6f7";
      prompt = "#cba6f7";
      pointer = "#f5e0dc";
      spinner = "#f5e0dc";
      marker = "#b4befe";
      "selected-bg" = "#45475a";
      border = "#313244";
      label = "#cdd6f4";
    };
  };
}
