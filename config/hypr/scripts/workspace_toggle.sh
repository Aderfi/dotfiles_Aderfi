#!/bin/bash

# Archivo para guardar el último workspace
LAST_WORKSPACE_FILE="/tmp/hypr_last_workspace_${USER}"

# Obtener el workspace actual
CURRENT_WORKSPACE=$(hyprctl -j activeworkspace | jq -r '.id')

# Leer el último workspace guardado
if [ -f "$LAST_WORKSPACE_FILE" ]; then
    LAST_WORKSPACE=$(cat "$LAST_WORKSPACE_FILE")
else
    LAST_WORKSPACE=""
fi

# Si no hay último workspace guardado o es el mismo que el actual, no hacer nada
if [ -z "$LAST_WORKSPACE" ] || [ "$LAST_WORKSPACE" -eq "$CURRENT_WORKSPACE" ]; then
    # Guardar el actual y salir (primera ejecución o mismo workspace)
    echo "$CURRENT_WORKSPACE" > "$LAST_WORKSPACE_FILE"
    exit 0
fi

# Guardar el workspace actual antes de cambiar
echo "$CURRENT_WORKSPACE" > "$LAST_WORKSPACE_FILE"

# Cambiar al workspace anterior
hyprctl dispatch workspace "$LAST_WORKSPACE"