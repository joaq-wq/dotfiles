#!/bin/sh
# =============================================================
#  ████████╗██╗  ██╗███████╗███╗   ███╗███████╗
#  ╚══██╔══╝██║  ██║██╔════╝████╗ ████║██╔════╝
#     ██║   ███████║█████╗  ██╔████╔██║█████╗
#     ██║   ██╔══██║██╔══╝  ██║╚██╔╝██║██╔══╝
#     ██║   ██║  ██║███████╗██║ ╚═╝ ██║███████╗
#     ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝
# Author: Adaptado para Hyprland por ChatGPT
# Data:   2025-05-28
# Info:   Configuração e lançamento do rice para Hyprland
# =============================================================

# Current Rice
read -r RICE < "$HOME"/.config/hyprland/.rice

# Load theme configuration
. "$HOME"/.config/hyprland/rices/"$RICE"/theme-config.bash

wait_for_termination() {
    process_name="$1"
    while pgrep -f "$process_name" >/dev/null; do
        sleep 0.2
    done
}

kill_processes() {
    # Kill polybar if running
    if pgrep -x polybar >/dev/null; then
        pkill polybar
        wait_for_termination polybar
    fi

    # Kill animated wallpaper if active
    if pgrep -x xwinwrap >/dev/null; then
        pkill xwinwrap
        wait_for_termination xwinwrap
    fi

    if [ -f /tmp/wall_refresh.pid ]; then
        kill "$(cat /tmp/wall_refresh.pid)" 2>/dev/null
        rm -f /tmp/wall_refresh.pid
    fi
}

apply_term_config() {
    # Alacritty
    sed -i "$HOME"/.config/alacritty/fonts.toml \
        -e "s/size = .*/size = $term_font_size/" \
        -e "s/family = .*/family = \"$term_font_name\"/"

    sed -i "$HOME"/.config/alacritty/alacritty.toml \
        -e "s|\"themes/.*\.toml\",|\"themes/${RICE}.toml\",|"

    # Kitty
    kitten themes --reload-in=all ${RICE}
}

apply_dunst_config() {
    dunst_config_file="$HOME/.config/hyprland/src/config/dunstrc"

    sed -i "$dunst_config_file" \
        -e "s/origin = .*/origin = ${dunst_origin}/" \
        -e "s/offset = .*/offset = ${dunst_offset}/" \
        -e "s/transparency = .*/transparency = ${dunst_transparency}/" \
        -e "s/^corner_radius = .*/corner_radius = ${dunst_corner_radius}/" \
        -e "s/frame_width = .*/frame_width = ${dunst_border}/" \
        -e "s/frame_color = .*/frame_color = \"${dunst_frame_color}\"/" \
        -e "s/font = .*/font = ${dunst_font}/" \
        -e "s/foreground='.*'/foreground='${blue}'/" \
        -e "s/icon_theme = .*/icon_theme = \"${dunst_icon_theme}, Adwaita\"/"

    sed -i '/urgency_low/Q' "$dunst_config_file"
    cat >>"$dunst_config_file" <<-_EOF_
        [urgency_low]
        timeout = 3
        background = "${bg}"
        foreground = "${green}"

        [urgency_normal]
        timeout = 5
        background = "${bg}"
        foreground = "${fg}"

        [urgency_critical]
        timeout = 0
        background = "${bg}"
        foreground = "${red}"
    _EOF_

    dunstctl reload "$dunst_config_file"
}

apply_gtk_appearance() {
    sed -i "$HOME"/.config/hyprland/src/config/xsettingsd \
        -e "s|Net/ThemeName .*|Net/ThemeName \"$gtk_theme\"|" \
        -e "s|Net/IconThemeName .*|Net/IconThemeName \"$gtk_icons\"|" \
        -e "s|Gtk/CursorThemeName .*|Gtk/CursorThemeName \"$gtk_cursor\"|"

    sed -i -e "s/Inherits=.*/Inherits=$gtk_cursor/" "$HOME"/.icons/default/index.theme

    if pidof -q xsettingsd; then
        pkill -1 xsettingsd
    fi
    xsetroot -cursor_name left_ptr
}

apply_eww_colors() {
    cat >"$HOME"/.config/hyprland/eww/colors.scss <<-EOF
        \$bg: ${bg};
        \$bg-alt: ${accent_color};
        \$fg: ${fg};
        \$black: ${blackb};
        \$red: ${red};
        \$green: ${green};
        \$yellow: ${yellow};
        \$blue: ${blue};
        \$magenta: ${magenta};
        \$cyan: ${cyan};
        \$archicon: ${arch_icon};
    EOF
}

apply_menu_colors() {
    # Jgmenu
    sed -i "$HOME"/.config/hyprland/src/config/jgmenurc \
        -e "s/color_menu_bg = .*/color_menu_bg = ${jg_bg}/" \
        -e "s/color_norm_fg = .*/color_norm_fg = ${jg_fg}/" \
        -e "s/color_sel_bg = .*/color_sel_bg = ${jg_sel_bg}/" \
        -e "s/color_sel_fg = .*/color_sel_fg = ${jg_sel_fg}/" \
        -e "s/color_sep_fg = .*/color_sep_fg = ${jg_sep}/"

    # Rofi launchers
    cat >"$HOME"/.config/hyprland/src/rofi-themes/shared.rasi <<-EOF
        * {
            font: "${rofi_font}";
            background: ${rofi_background};
            bg-alt: ${rofi_bg_alt};
            background-alt: ${rofi_background_alt};
            foreground: ${rofi_fg};
            selected: ${rofi_selected};
            active: ${rofi_active};
            urgent: ${rofi_urgent};

            img-background: url("~/.config/hyprland/rices/${RICE}/rofi.webp", width);
        }
    EOF
}

apply_geany_theme(){
    sed -i "$HOME"/.config/geany/geany.conf \
        -e "s/color_scheme=.*/color_scheme=$geany_theme.conf/g"
}

apply_wallpaper () {
    case $ENGINE in
        "Theme")
            feh -z --no-fehbg --bg-fill "${HOME}"/.config/hyprland/rices/"${RICE}"/walls ;;
        "CustomDir")
            feh -z --no-fehbg --bg-fill "$CUSTOM_DIR" ;;
        "CustomImage")
            feh --no-fehbg --bg-fill "$CUSTOM_WALL" ;;
        "CustomAnimated")
            AnimatedWall --start "$CUSTOM_ANIMATED" ;;
        "Slideshow")
            (
                while true; do
                    feh -z --no-fehbg --bg-fill "${HOME}"/.config/hyprland/rices/"${RICE}"/walls
                    sleep 900
                done
            ) &
            echo $! > /tmp/wall_refresh.pid ;;
        *)
            feh -z --no-fehbg --bg-fill "${HOME}"/.config/hyprland/rices/"${RICE}"/walls ;;
    esac
}

apply_bar() {
    # Launch polybar
    "$HOME"/.config/hyprland/rices/"$RICE"/launch-polybar.sh
}

### Aplicar configurações

kill_processes
apply_term_config
apply_gtk_appearance
apply_dunst_config
apply_eww_colors
apply_menu_colors
apply_geany_theme
apply_wallpaper
apply_bar

