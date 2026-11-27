palette_file=$1
config_home=$2
claude_dir=$3
cava_config="$config_home/cava/config"
cava_base="$config_home/cava/base.conf"
rmpc_theme="$config_home/rmpc/themes/dms.ron"

# Cava sigue siendo usable antes de que DMS genere su primera paleta.
if [[ ! -s $palette_file ]]; then
    if [[ ! -e $cava_config ]]; then
        install -m 600 "$cava_base" "$cava_config"
    fi
    exit 0
fi

palette=$(jq -ce '
    .mode as $mode
    | .colors[$mode] + {
        mode: $mode,
        red: .dank16.color1[$mode],
        green: .dank16.color2[$mode],
        yellow: .dank16.color3[$mode],
        blue: .dank16.color4[$mode],
        cyan: .dank16.color6[$mode],
        bright_yellow: .dank16.color11[$mode]
    }
' "$palette_file")

render_template() {
    jq -Rrs --argjson palette "$palette" '
        gsub("@(?<role>[a-z_]+)@";
            .role as $role
            | ($palette[$role] // error("Unknown DMS color role: \($role)")))
        | rtrimstr("\n")
    '
}

write_theme() {
    local target=$1 contents=$2
    changed=false
    if printf '%s\n' "$contents" | cmp -s - "$target"; then
        return
    fi
    mkdir -p "$(dirname -- "$target")"
    local tmp
    tmp=$(mktemp -- "$target.XXXXXX")
    if ! printf '%s\n' "$contents" > "$tmp" || ! mv -T -- "$tmp" "$target"; then
        rm -f -- "$tmp"
        return 1
    fi
    changed=true
}

rmpc_contents=$(render_template < "$config_home/rmpc/dms-theme.ron.in")
write_theme "$rmpc_theme" "$rmpc_contents"
if $changed && pgrep -u "$UID" -x rmpc >/dev/null; then
    rmpc remote set theme "$rmpc_theme" >/dev/null 2>&1 || true
fi

cava_colors=$(render_template <<'EOF'
[color]
background='default'
gradient=1
gradient_color_1='@secondary@'
gradient_color_2='@blue@'
gradient_color_3='@cyan@'
gradient_color_4='@primary@'
gradient_color_5='@tertiary@'
gradient_color_6='@red@'
gradient_color_7='@yellow@'
gradient_color_8='@bright_yellow@'
EOF
)
cava_settings=$(< "$cava_base")
write_theme "$cava_config" "$cava_settings"$'\n\n'"$cava_colors"
if $changed; then
    for pid in $(pgrep -u "$UID" -x cava || true); do
        # Cava sin argumentos lee este config. DMS usa cava -p con otro.
        if mapfile -d '' -t args 2>/dev/null < "/proc/$pid/cmdline" && [[ ${#args[@]} -eq 1 ]]; then
            kill -USR2 "$pid" 2>/dev/null || true
        fi
    done
fi

if [[ -n $claude_dir ]]; then
    claude_theme=$(render_template <<'EOF'
{
  "name": "DMS",
  "base": "@mode@",
  "overrides": {
    "claude": "@primary@",
    "text": "@on_surface@",
    "error": "@error@",
    "success": "@green@",
    "warning": "@yellow@",
    "promptBorder": "@primary@",
    "diffAdded": "@surface_container_highest@",
    "diffRemoved": "@surface_container_high@",
    "userMessageBackground": "@surface_container@"
  }
}
EOF
)
    write_theme "$claude_dir/dms.json" "$claude_theme"
fi
