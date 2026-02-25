#!/bin/bash
# workspace_toggle.sh — Sway edition
# Equivalente al workspace_toggle.sh de Hyprland

LAST_WORKSPACE_FILE="/tmp/sway_last_workspace_${USER}"

# Obtener workspace actual
CURRENT_WORKSPACE=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused==true) | .name')

# Leer el último workspace guardado
if [ -f "$LAST_WORKSPACE_FILE" ]; then
    LAST_WORKSPACE=$(cat "$LAST_WORKSPACE_FILE")
else
    LAST_WORKSPACE=""
fi

# Si no hay último workspace o es el mismo, guardar y salir
if [ -z "$LAST_WORKSPACE" ] || [ "$LAST_WORKSPACE" = "$CURRENT_WORKSPACE" ]; then
    echo "$CURRENT_WORKSPACE" > "$LAST_WORKSPACE_FILE"
    exit 0
fi

# Guardar el actual y cambiar al anterior
echo "$CURRENT_WORKSPACE" > "$LAST_WORKSPACE_FILE"
swaymsg workspace "$LAST_WORKSPACE"
