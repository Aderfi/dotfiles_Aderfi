#!/bin/bash
# Extrae los binarios disponibles, los pasa a wofi y ejecuta la selección a través de systemd

# Extraemos la lista de ejecutables del PATH y lanzamos la interfaz de wofi
COMANDO=$(compgen -c | sort -u | wofi --show drun --prompt "Buscar aplicación...")

# Si el usuario seleccionó una aplicación y no presionó Esc
if [ -n "$COMANDO" ]; then
    uwsm app -- "$COMANDO"
fi
