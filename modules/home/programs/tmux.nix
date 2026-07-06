{ pkgs, ... }:

let
  catppuccinTmux = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "tmux";
    rev = "v2.3.0";
    hash = "sha256-3CJRQCgS8NAN7vOLBjNGiHbGXTIrIyY/FLmfZrXcEYc=";
  };
in

{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    clock24 = true;
    escapeTime = 0;
    keyMode = "vi";
    mouse = true;
    terminal = "tmux-256color";

    extraConfig = ''
      set -g pane-base-index 1
      set -g renumber-windows on
      set -g status-position bottom
      set -g status-interval 5
      set -g status-left-length 100
      set -g status-right-length 100

      set -g @catppuccin_flavor "mocha"
      set -g @catppuccin_window_status_style "rounded"
      set -g @catppuccin_window_current_number_color "#{@thm_mauve}"
      set -g @catppuccin_pane_color "#{@thm_mauve}"
      set -g @catppuccin_pane_active_border_style "fg=#{@thm_mauve}"

      run ${catppuccinTmux}/catppuccin.tmux

      set -g status-left ""
      set -g status-right "#{E:@catppuccin_status_application}"
      set -ag status-right "#{E:@catppuccin_status_session}"
      set -ag status-right " %H:%M"
    '';
  };
}
