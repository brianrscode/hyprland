#!/bin/sh

timestamp=$(date +%Y-%m-%d-%H%M%S)
dir="$HOME/Pictures/ScreenShots"
filename="$dir/shot-${timestamp}.png"
tmpfile="${XDG_RUNTIME_DIR:-/tmp}/screenshoter-${timestamp}.png"

[ -d "$dir" ] || mkdir -p "$dir"

# Rofi options
s_select="󰹑"
s_full=""
s_in3="󰔝"
s_all="󰍹"

notify() {
    if [ ! -n "$2" ] && [ ! -n "$3" ]; then
        notify-send "Screenshot"
    fi

    if [ ! -n "$3" ]; then
        notify-send "Screenshot" "$1" -i "$2"
    fi

    notify-send "Screenshot" "$1" -i "$2" -t "$3"
}

require_cmds() {
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            notify "Missing dependency: $cmd" user-trash
            exit 1
        fi
    done
}

get_current_monitor_geometry() {
    cursor=$(hyprctl cursorpos 2>/dev/null | tr -d ',')
    cursor_x=${cursor%% *}
    cursor_y=${cursor##* }

    hyprctl monitors -j | jq -r --argjson cx "$cursor_x" --argjson cy "$cursor_y" '
        .[]
        | select($cx >= .x and $cx < (.x + .width) and $cy >= .y and $cy < (.y + .height))
        | "\(.x),\(.y) \(.width)x\(.height)"
    ' | head -n 1
}

rofi_cmd() {
    rofi -dmenu \
        -markup-rows \
        -theme "~/.config/hypr/rofi/screenshoter/screenshot.rasi"
    # rofi -dmenu \
    #     -markup-rows \
    #     -mesg "Directory :: $dir" \
    #     -theme "~/.config/hypr/rofi/screenshoter/screenshot.rasi"
}

run_rofi() {
    printf "%s\n%s\n%s\n%s\n" "$s_select" "$s_full" "$s_in3" "$s_all" | rofi_cmd
}

show_result() {
    if [ -e "$filename" ]; then
        wl-copy --type image/png <"$filename"
        notify "Screenshot saved an copied to clipboard" "$filename" "4000"
    else
        notify "Screenshot canceled" user-trash "4000"
    fi
}

open_swappy() {
    swappy -f "$tmpfile" -o "$filename"
    rm -f "$tmpfile"
    show_result
}

take_screenshot() {
    mode="$1"
    all_monitors="$2"

    case "$mode" in
    full)
        sleep 0.5
        if [ "$all_monitors" = "true" ]; then
            grim "$tmpfile"
        else
            geometry=$(get_current_monitor_geometry)
            [ -n "$geometry" ] && grim -g "$geometry" "$tmpfile"
        fi

        if [ -e "$tmpfile" ]; then
            open_swappy
        else
            notify "Screenshot canceled" user-trash
        fi
        ;;
    select)
        geometry=$(slurp)
        [ -n "$geometry" ] && grim -g "$geometry" "$tmpfile"
        if [ -e "$tmpfile" ]; then
            wl-copy --type image/png <"$filename"
            notify "Screenshot saved an copied to clipboard" "$filename" "1500"
        else
            notify "Screenshot canceled" user-trash
        fi
        ;;
    esac

    # if [ -e "$tmpfile" ]; then
    #     open_swappy
    # else
    #     notify "Screenshot canceled" user-trash
    # fi
}

countdown() {
    for sec in $(seq "$1" -1 1); do
        notify "Taking shot in $sec" camera-photo "900"
        sleep 1
    done
}

require_cmds grim slurp swappy wl-copy hyprctl jq rofi notify-send

select_option="$(run_rofi)"
case "$select_option" in
"$s_full")
    take_screenshot full false
    ;;
"$s_select")
    take_screenshot select false
    ;;
"$s_in3")
    countdown 3 && take_screenshot full false
    ;;
"$s_all")
    take_screenshot full true
    ;;
esac
