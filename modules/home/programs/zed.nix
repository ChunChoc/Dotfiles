{ lib, osConfig, ... }:

{
  # Gated con el mismo flag que instala el binario (feature development).
  programs.zed-editor = lib.mkIf osConfig.myFeatures.development {
    enable = true;

    # Zed itself is installed by the development feature. This module owns only
    # user configuration so editor settings remain reproducible and focused.
    package = null;

    extensions = [
      "astro"
      "catppuccin"
      "django"
      "git-firefly"
      "html"
      "kdl"
      "latex"
      "log"
      "material-icon-theme"
      "nix"
      "toml"
    ];

    userSettings = {
      buffer_font_family = "JetBrainsMono Nerd Font";
      buffer_font_size = 15;
      cli_default_open_behavior = "existing_window";
      icon_theme = "Material Icon Theme";
      terminal = {
        copy_on_select = false;
        font_family = "JetBrainsMono Nerd Font";
      };
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      theme = {
        mode = "system";
        light = "One Light";
        dark = "Catppuccin Mocha";
      };
      ui_font_size = 16;
    };

    userKeymaps = [
      {
        context = "Terminal";
        bindings = {
          shift-enter = [
            "terminal::SendText"
            (builtins.fromJSON ''"\u001b\r"'')
          ];
        };
      }
      {
        bindings = {
          alt-h = "agent::FocusAgent";
          alt-j = "terminal_panel::ToggleFocus";
        };
      }
    ];
  };
}
