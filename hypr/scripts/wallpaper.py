#!/usr/bin/env python3

from pathlib import Path
import subprocess

# Configuración
WALL_DIR = Path.home() / "wallpapers"

ROFI_COMMAND = [
    "rofi",
    "-i",
    "-show",
    "-dmenu",
    "-config",
    str(Path.home() / ".config/hypr/rofi/wallpaper_switcher/wallpaper.rasi"),
]

IMAGE_EXTENSIONS = {
    ".jpg",
    ".jpeg",
    ".png",
    ".gif",
}


def notify(msg: str, ico: str = "dialog-information") -> None:
    subprocess.run(
        [
            "notify-send",
            "Error",
            f"{msg}",
            "-i",
            f"{ico}",
        ]
    )


def kill_if_running(process_name: str):
    """Cierra un proceso si está en ejecución."""
    subprocess.run(
        ["pkill", process_name],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def get_wallpapers():
    """Obtiene todas las imágenes del directorio de wallpapers."""
    return sorted(
        [
            path
            for path in WALL_DIR.rglob("*")
            if path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS
        ]
    )


def build_rofi_menu(wallpapers):
    """Construye el menú de Rofi con iconos."""
    entries = []

    for wallpaper in wallpapers:
        entries.append(f"{wallpaper.name}\x00icon\x1f{wallpaper}")

    return "\n".join(entries)


def show_rofi(menu_text):
    """Muestra Rofi y devuelve la selección."""
    result = subprocess.run(
        ROFI_COMMAND,
        input=menu_text,
        text=True,
        capture_output=True,
    )

    return result.stdout.strip()


def set_wallpaper(wallpaper_path: Path):
    """Aplica el wallpaper usando awww."""
    subprocess.run(
        [
            "awww",
            "img",
            "--transition-type",
            "grow",
            "--transition-pos",
            "0.854,0.977",
            "--transition-step",
            "90",
            str(wallpaper_path),
        ]
    )


def main():
    # Cerrar swaybg si está activo
    kill_if_running("swaybg")

    wallpapers = get_wallpapers()

    if not wallpapers:
        notify("No se encontraron wallpapers.", "dialog-error")
        return

    menu_text = build_rofi_menu(wallpapers)
    choice = show_rofi(menu_text)

    if not choice:
        return

    selected_wallpaper = next(
        (wp for wp in wallpapers if wp.name == choice),
        None,
    )

    if selected_wallpaper:
        set_wallpaper(selected_wallpaper)
    else:
        notify("Wallpaper no encontrado.", "dialog-error")


if __name__ == "__main__":
    kill_if_running("rofi")
    main()
