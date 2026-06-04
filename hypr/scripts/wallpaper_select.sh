#!/bin/bash

# WALLPAPERS PATH
wallDIR="$HOME/wallpapers"

# Monitor focused (por si lo usas después)
focused_monitor=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')

# Check if swaybg is running
if pidof swaybg >/dev/null; then
    pkill swaybg
fi

# Retrieve image files
mapfile -d '' PICS < <(
    find "${wallDIR}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) -print0
)

# Rofi command
rofi_command="rofi -i -show -dmenu -config ~/.config/hypr/rofi/wallpaper_switcher/wallpaper.rasi"

# Sorting Wallpapers
menu() {
    IFS=$'\n' sorted_options=($(sort <<<"${PICS[*]}"))

    for pic_path in "${sorted_options[@]}"; do
        pic_name=$(basename "$pic_path")

        # Mostrar icono para imágenes normales, solo nombre para gif
        if [[ ! "$pic_name" =~ \.gif$ ]]; then
            printf "%s\x00icon\x1f%s\n" "$(echo "$pic_name" | cut -d. -f1)" "$pic_path"
        else
            printf "%s\n" "$pic_name"
        fi
    done
}

# Choice of wallpapers
main() {
    choice=$(menu | $rofi_command)

    choice=$(echo "$choice" | xargs)

    if [[ -z "$choice" ]]; then
        echo "No choice selected. Exiting."
        exit 0
    fi

    # Find selected image
    pic_index=-1
    for i in "${!PICS[@]}"; do
        filename=$(basename "${PICS[$i]}")
        if [[ "$filename" == "$choice"* ]]; then
            pic_index=$i
            break
        fi
    done

    if [[ $pic_index -ne -1 ]]; then
        awww img --transition-type grow --transition-pos 0.854,0.977 --transition-step 90 "${PICS[$pic_index]}"
    else
        echo "Image not found."
        exit 1
    fi
}

# Prevent multiple rofi instances
if pidof rofi >/dev/null; then
    pkill rofi
    sleep 1
fi

main
