#!/bin/sh

# hyprshot -m region --raw | satty --filename -

# salida=hyprshot -m region --raw
#
# wl-copy --type image/png <"$filename"
# notify "Screenshot saved an copied to clipboard" "$filename" "1500"

require_cmds() {
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            notify "Missing dependency: $cmd" user-trash
            exit 1
        fi
    done
}

notify() {
    if [ ! -n "$2" ] && [ ! -n "$3" ]; then
        notify-send "Screenshot"
    fi

    if [ ! -n "$3" ]; then
        notify-send "Screenshot" "$1" -i "$2"
    fi

    notify-send "Screenshot" "$1" -i "$2" -t "$3"
}

require_cmds hyprshot satty

tmpfile=$(mktemp --suffix=.png)

if hyprshot -m region --raw | tee "$tmpfile" | wl-copy --type image/png >/dev/null; then
    notify "Screenshot copied to clipboard" "$tmpfile" "1500"
fi

sleep 2
rm -f "$tmpfile"
