#!/bin/bash

THEME="$HOME/.config/hypr/rofi/clipboard/clipboard.rasi"
CLEAR_OPTION="󰆴  Borrar todo"

selection="$(
    {
        echo "$CLEAR_OPTION"
        cliphist list
    } | rofi \
        -theme "$THEME" \
        -dmenu \
        -sync \
        -i \
        -p ""
)"

case "$selection" in
"$CLEAR_OPTION")
    cliphist wipe
    notify-send "Portapapeles" "Historial borrado" -i user-trash -t 1500
    exit 0
    ;;

"")
    exit 0
    ;;

*)
    echo "$selection" | cliphist decode | wl-copy
    notify-send "Portapapeles" "Copiado al portapapeles"
    exit 0
    ;;
esac
