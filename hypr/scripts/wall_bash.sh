#!/bin/sh

# =========================
# Configuración
# =========================

wall_dir="$HOME/wallpapers"
cacheDir="$HOME/.cache/$USER/wallpaper_switcher"

rofi_command="rofi -i -show -dmenu -config $HOME/.config/hypr/rofi/wallpaper_switcher/wallpaper.rasi"

thumb_size="500x500"

# =========================
# Validaciones
# =========================

if [ ! -d "$wall_dir" ]; then
    notify-send "Wallpaper Switcher" "No existe el directorio: $wall_dir" -i dialog-error
    exit 1
fi

command -v magick >/dev/null 2>&1 || {
    notify-send "Wallpaper Switcher" "ImageMagick no está instalado." -i dialog-error
    exit 1
}

command -v rofi >/dev/null 2>&1 || {
    notify-send "Wallpaper Switcher" "Rofi no está instalado." -i dialog-error
    exit 1
}

command -v awww >/dev/null 2>&1 || {
    notify-send "Wallpaper Switcher" "awww no está instalado." -i dialog-error
    exit 1
}

# Crear caché si no existe
[ -d "$cacheDir" ] || mkdir -p "$cacheDir"

# =========================
# Número de procesos paralelos
# =========================

get_optimal_jobs() {
    cores=$(nproc)

    if [ "$cores" -le 2 ]; then
        echo 2
    elif [ "$cores" -gt 4 ]; then
        echo 4
    else
        echo $((cores - 1))
    fi
}

PARALLEL_JOBS=$(get_optimal_jobs)

# =========================
# Procesar thumbnails
# =========================

process_func_def='process_image() {
    imagen="$1"

    relative_path="${imagen#"$wall_dir"/}"

    cache_name=$(printf "%s" "$relative_path" | sed "s|/|_|g")
    cache_file="${cacheDir}/${cache_name}.png"
    md5_file="${cacheDir}/.${cache_name}.md5"
    lock_file="${cacheDir}/.lock_${cache_name}"

    current_md5=$(md5sum "$imagen" | cut -d " " -f1)

    (
        flock -x 9

        if [ ! -f "$cache_file" ] || [ ! -f "$md5_file" ] || [ "$current_md5" != "$(cat "$md5_file" 2>/dev/null)" ]; then
            magick "$imagen" \
                -resize '"$thumb_size"^' \
                -gravity center \
                -extent '"$thumb_size"' \
                "$cache_file"

            echo "$current_md5" > "$md5_file"
        fi

        rm -f "$lock_file"
    ) 9>"$lock_file"
}'

export process_func_def cacheDir wall_dir thumb_size

# Limpiar locks viejos
rm -f "${cacheDir}"/.lock_* 2>/dev/null || true

# Generar thumbnails en paralelo
find "$wall_dir" -type f \( \
    -iname "*.jpg" -o \
    -iname "*.jpeg" -o \
    -iname "*.png" -o \
    -iname "*.webp" \
    \) -print0 |
    xargs -0 -P "$PARALLEL_JOBS" -I {} sh -c "$process_func_def; process_image \"{}\""

# =========================
# Limpiar caché huérfana
# =========================

for cached in "$cacheDir"/*.png; do
    [ -f "$cached" ] || continue

    cached_base=$(basename "$cached" .png)

    found_original=false

    find "$wall_dir" -type f \( \
        -iname "*.jpg" -o \
        -iname "*.jpeg" -o \
        -iname "*.png" -o \
        -iname "*.webp" \
        \) -print0 | while IFS= read -r -d '' original; do
        relative_path="${original#"$wall_dir"/}"
        expected_name=$(printf "%s" "$relative_path" | sed "s|/|_|g")

        if [ "$expected_name" = "$cached_base" ]; then
            exit 0
        fi
    done

    if [ $? -ne 0 ]; then
        rm -f "$cached" \
            "${cacheDir}/.${cached_base}.md5" \
            "${cacheDir}/.lock_${cached_base}"
    fi
done

# Limpiar locks restantes
rm -f "${cacheDir}"/.lock_* 2>/dev/null || true

# =========================
# Lanzar Rofi
# =========================

wall_selection=$(
    find "$wall_dir" -type f \( \
        -iname "*.jpg" -o \
        -iname "*.jpeg" -o \
        -iname "*.png" -o \
        -iname "*.webp" \
        \) -print0 |
        while IFS= read -r -d '' wallpaper; do
            relative_path="${wallpaper#"$wall_dir"/}"
            cache_name=$(printf "%s" "$relative_path" | sed "s|/|_|g")
            cache_file="${cacheDir}/${cache_name}.png"

            printf '%s\000icon\037%s\n' "$relative_path" "$cache_file"
        done |
        LC_ALL=C sort |
        $rofi_command
)

# =========================
# Aplicar wallpaper
# =========================

[ -z "$wall_selection" ] && exit 0

selected_wallpaper="$wall_dir/$wall_selection"

if [ ! -f "$selected_wallpaper" ]; then
    notify-send "Wallpaper Switcher" "Wallpaper no encontrado." -i dialog-error
    exit 1
fi

# Cerrar swaybg si está activo
pkill swaybg 2>/dev/null || true

# Aplicar wallpaper con awww
awww img \
    --transition-type grow \
    --transition-pos 0.854,0.977 \
    --transition-step 90 \
    "$selected_wallpaper"
