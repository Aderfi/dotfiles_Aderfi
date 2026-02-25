#!/bin/bash
# workspace_toggle.sh — Hyprland edition

LAST_WORKSPACE_FILE="/tmp/hypr_last_workspace_${USER}"

CURRENT_WORKSPACE=$(hyprctl -j activeworkspace | jq -r '.id')

if [ -f "$LAST_WORKSPACE_FILE" ]; then
    LAST_WORKSPACE=$(cat "$LAST_WORKSPACE_FILE")
else
    LAST_WORKSPACE=""
fi

if [ -z "$LAST_WORKSPACE" ] || [ "$LAST_WORKSPACE" -eq "$CURRENT_WORKSPACE" ]; then
    echo "$CURRENT_WORKSPACE" > "$LAST_WORKSPACE_FILE"
    exit 0
fi

echo "$CURRENT_WORKSPACE" > "$LAST_WORKSPACE_FILE"
hyprctl dispatch workspace "$LAST_WORKSPACE"
