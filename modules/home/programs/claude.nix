{ lib, pkgs, ... }:

{
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

      exec ${pkgs.nodejs}/bin/npx -y @upstash/context7-mcp --api-key "$CONTEXT7_API_KEY"
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
}
