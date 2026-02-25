#!/bin/bash
# Matar instancias previas
killall waybar
pkill waybar

# Cargar configuración nueva (la nuestra)
waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css &
