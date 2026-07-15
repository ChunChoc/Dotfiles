{ lib, pkgs, osConfig, ... }:

let
  claudePermissionDenyRules = [
    "Bash(rm -rf /)"
    "Bash(rm -rf /*)"
    "Bash(rm -fr /)"
    "Bash(rm -fr /*)"
    "Bash(sudo rm -rf /)"
    "Bash(sudo rm -rf /*)"
    "Bash(sudo rm -fr /)"
    "Bash(sudo rm -fr /*)"
    "Bash(rm -rf ~)"
    "Bash(rm -rf ~/)"
    "Bash(rm -rf ~/*)"
    "Bash(rm -fr ~)"
    "Bash(rm -fr ~/)"
    "Bash(rm -fr ~/*)"
    "Bash(sudo rm -rf ~)"
    "Bash(sudo rm -rf ~/)"
    "Bash(sudo rm -rf ~/*)"
    "Bash(sudo rm -fr ~)"
    "Bash(sudo rm -fr ~/)"
    "Bash(sudo rm -fr ~/*)"
    "Bash(rm -rf $HOME)"
    "Bash(rm -rf $HOME/)"
    "Bash(rm -rf $HOME/*)"
    "Bash(rm -fr $HOME)"
    "Bash(rm -fr $HOME/)"
    "Bash(rm -fr $HOME/*)"
    "Bash(sudo rm -rf $HOME)"
    "Bash(sudo rm -rf $HOME/)"
    "Bash(sudo rm -rf $HOME/*)"
    "Bash(sudo rm -fr $HOME)"
    "Bash(sudo rm -fr $HOME/)"
    "Bash(sudo rm -fr $HOME/*)"
    "Read(.env)"
    "Read(.env.*)"
    "Read(**/.env)"
    "Read(**/.env.*)"
    "Edit(.env)"
    "Edit(.env.*)"
    "Edit(**/.env)"
    "Edit(**/.env.*)"
    "Read(**/secrets/**)"
    "Edit(**/secrets/**)"
    "Read(~/Dotfiles/.secrets/**)"
    "Edit(~/Dotfiles/.secrets/**)"
    "Read(~/.ssh/**)"
    "Edit(~/.ssh/**)"
    "Read(~/.aws/credentials)"
    "Edit(~/.aws/credentials)"
    "Read(~/.config/gh/hosts.yml)"
    "Edit(~/.config/gh/hosts.yml)"
    "Read(**/*.pem)"
    "Edit(**/*.pem)"
    "Read(**/*.key)"
    "Edit(**/*.key)"
    "Read(~/.gnupg/**)"
    "Edit(~/.gnupg/**)"
    "Read(~/.pki/**)"
    "Edit(~/.pki/**)"
    "Read(~/.local/share/keyrings/**)"
    "Edit(~/.local/share/keyrings/**)"
  ];

  # Tema Catppuccin Mocha (acento mauve) para la TUI de Claude Code.
  # Tokens según code.claude.com/docs/en/terminal-config#create-a-custom-theme
  claudeCatppuccinTheme = {
    name = "Catppuccin Mocha";
    base = "dark";
    overrides = {
      claude = "#cba6f7";
      text = "#cdd6f4";
      error = "#f38ba8";
      success = "#a6e3a1";
      warning = "#f9e2af";
      promptBorder = "#cba6f7";
      diffAdded = "#2e3a30";
      diffRemoved = "#3c2a37";
      userMessageBackground = "#313244";
    };
  };
in

{
  # Toda la config de Claude Code (MCP, denies, plugin) se aplica solo si el
  # feature development está activo, igual que el binario que la usa.
  config = lib.mkIf osConfig.myFeatures.development {

  home.file.".claude/themes/catppuccin-mocha.json".text = builtins.toJSON claudeCatppuccinTheme;

  home.file.".local/bin/context7-mcp" = {
    executable = true;
    text = ''
      #!${pkgs.fish}/bin/fish

      if test -f ~/Dotfiles/.secrets/secrets.env
        source ~/Dotfiles/.secrets/secrets.env
      end

      if not set -q CONTEXT7_API_KEY
        echo "CONTEXT7_API_KEY is not set. Add it to ~/Dotfiles/.secrets/secrets.env" >&2
        exit 1
      end

      set -lx PATH ${pkgs.nodejs}/bin $PATH
      exec ${pkgs.nodejs}/bin/npx -y @upstash/context7-mcp --api-key "$CONTEXT7_API_KEY"
    '';
  };

  home.file.".local/bin/magic-mcp" = {
    executable = true;
    text = ''
      #!${pkgs.fish}/bin/fish

      if test -f ~/Dotfiles/.secrets/secrets.env
        source ~/Dotfiles/.secrets/secrets.env
      end

      if not set -q _21_DEV_API_KEY
        echo "_21_DEV_API_KEY is not set. Add it to ~/Dotfiles/.secrets/secrets.env" >&2
        exit 1
      end

      set -x API_KEY "$_21_DEV_API_KEY"
      exec ${pkgs.bun}/bin/bunx -y @21st-dev/magic@latest
    '';
  };

  home.file.".local/bin/chrome-devtools-mcp" = {
    executable = true;
    text = ''
      #!${pkgs.fish}/bin/fish

      set -lx PATH ${pkgs.nodejs}/bin $PATH
      exec ${pkgs.nodejs}/bin/npx -y chrome-devtools-mcp@latest \
        --executablePath=${pkgs.brave}/bin/brave \
        --isolated \
        --no-usage-statistics \
        --no-performance-crux
    '';
  };

  home.activation.claudeContext7Mcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    claude_json="$HOME/.claude.json"
    tmp_file="$(${pkgs.coreutils}/bin/mktemp "''${TMPDIR:-/tmp}/claude-json.XXXXXX")"

    if ! test -f "$claude_json"; then
      printf '{}\n' > "$claude_json"
    fi

    ${pkgs.jq}/bin/jq --arg command "$HOME/.local/bin/context7-mcp" '
      .mcpServers.context7 = {
        "command": $command,
        "args": []
      }
    ' "$claude_json" > "$tmp_file"

    ${pkgs.coreutils}/bin/mv "$tmp_file" "$claude_json"
  '';

  home.activation.claudeMagicMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    claude_json="$HOME/.claude.json"
    tmp_file="$(${pkgs.coreutils}/bin/mktemp "''${TMPDIR:-/tmp}/claude-json.XXXXXX")"

    if ! test -f "$claude_json"; then
      printf '{}\n' > "$claude_json"
    fi

    ${pkgs.jq}/bin/jq --arg command "$HOME/.local/bin/magic-mcp" '
      .mcpServers.magic = {
        "command": $command,
        "args": []
      }
    ' "$claude_json" > "$tmp_file"

    ${pkgs.coreutils}/bin/mv "$tmp_file" "$claude_json"
  '';

  home.activation.claudeChromeDevToolsMcp = lib.hm.dag.entryAfter [ "claudeMagicMcp" ] ''
    claude_json="$HOME/.claude.json"
    tmp_file="$(${pkgs.coreutils}/bin/mktemp "''${TMPDIR:-/tmp}/claude-json.XXXXXX")"

    if ! test -f "$claude_json"; then
      printf '{}\n' > "$claude_json"
    fi

    ${pkgs.jq}/bin/jq --arg command "$HOME/.local/bin/chrome-devtools-mcp" '
      .mcpServers["chrome-devtools"] = {
        "command": $command,
        "args": []
      }
    ' "$claude_json" > "$tmp_file"

    ${pkgs.coreutils}/bin/mv "$tmp_file" "$claude_json"
  '';

  home.activation.claudeDangerousPermissionDenies = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings_dir="$HOME/.claude"
    settings_json="$settings_dir/settings.json"
    tmp_file="$(${pkgs.coreutils}/bin/mktemp "''${TMPDIR:-/tmp}/claude-settings.XXXXXX")"

    ${pkgs.coreutils}/bin/mkdir -p "$settings_dir"

    if ! test -f "$settings_json"; then
      printf '{}\n' > "$settings_json"
    fi

    ${pkgs.jq}/bin/jq --argjson denyRules '${builtins.toJSON claudePermissionDenyRules}' '
      .permissions = ((.permissions // {}) | if type == "object" then . else {} end)
      | .permissions.deny = (((.permissions.deny // []) + $denyRules) | unique)
    ' "$settings_json" > "$tmp_file"

    ${pkgs.coreutils}/bin/mv "$tmp_file" "$settings_json"
  '';

  # El settings.json es mutable (Claude Code escribe en él), así que el tema
  # se fija con jq igual que las deny rules, sin pisar el resto del archivo.
  home.activation.claudeCatppuccinTheme = lib.hm.dag.entryAfter [ "claudeDangerousPermissionDenies" ] ''
    settings_json="$HOME/.claude/settings.json"
    tmp_file="$(${pkgs.coreutils}/bin/mktemp "''${TMPDIR:-/tmp}/claude-settings.XXXXXX")"

    if ! test -f "$settings_json"; then
      printf '{}\n' > "$settings_json"
    fi

    ${pkgs.jq}/bin/jq '.theme = "custom:catppuccin-mocha"' "$settings_json" > "$tmp_file"

    ${pkgs.coreutils}/bin/mv "$tmp_file" "$settings_json"
  '';

  home.activation.claudeSuperpowersPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    claude_bin="${pkgs.claude-code}/bin/claude"

    if "$claude_bin" plugin list 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "superpowers@claude-plugins-official"; then
      "$claude_bin" plugin enable --scope user superpowers@claude-plugins-official >/dev/null 2>&1 || true
    else
      "$claude_bin" plugin install --scope user superpowers@claude-plugins-official
    fi
  '';

  };
}
