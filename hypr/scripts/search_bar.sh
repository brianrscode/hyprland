rofi_config="$HOME/.config/hypr/rofi/search_bar/config-search.rasi"

# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
    exit 0
fi

# Open rofi with a dmenu and pass the selected item to xdg-open for Google search
echo "" | rofi -dmenu -config "$rofi_config" -p "Search:" | xargs -I{} xdg-open "https://www.google.com/search?q={}"
