#!/bin/bash

WALLPAPER_DIR="$HOME/Desktop/Fondos"

case "$1" in
    --random)
        # Seleccionar wallpaper aleatorio
        WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | shuf -n 1)
        if [ -z "$WALLPAPER" ]; then
            notify-send "Waypaper" "No se encontraron imágenes en $WALLPAPER_DIR"
            exit 1
        fi
        # Matar swaybg anterior y lanzar con el nuevo wallpaper
        pkill -x swaybg
        swaybg -m fit -i "$WALLPAPER" &
        disown
        notify-send "Wallpaper" "$(basename "$WALLPAPER")" -i "$WALLPAPER"
        ;;
    *)
        # Selector interactivo con zenity
        WALLPAPER=$(zenity --file-selection --title="Seleccionar wallpaper" --filename="$WALLPAPER_DIR/" --file-filter="Imágenes | *.jpg *.jpeg *.png *.webp" 2>/dev/null)
        if [ -n "$WALLPAPER" ]; then
            pkill -x swaybg
            swaybg -m fit -i "$WALLPAPER" &
            disown
            notify-send "Wallpaper" "$(basename "$WALLPAPER")" -i "$WALLPAPER"
        fi
        ;;
esac
