#!/bin/bash

# Directorio donde guardar las capturas
OUTPUT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$OUTPUT_DIR"

# Nombre del archivo con fecha
FILENAME="Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
FILEPATH="$OUTPUT_DIR/$FILENAME"

case "$1" in
    gui)
        flameshot gui
        ;;

    full)
        flameshot full -p "$FILEPATH" -c -d 100
        notify-send "Captura realizada" "Guardada en $FILENAME y copiada." -i "$FILEPATH"
        ;;

    *)
        echo "Uso: $0 {gui|full}"
        exit 1
        ;;
esac
