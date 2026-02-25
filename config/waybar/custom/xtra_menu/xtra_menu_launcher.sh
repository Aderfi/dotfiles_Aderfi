#!/bin/bash
# Waybar pasa las coordenadas como {} {}
# Este script las captura y las pasa correctamente al Python

outp=$(hyprctl cursorpos)
click_x=$(echo "$outp" | cut -d ',' -f1 | tr -d "[:blank:]")
click_y=$(echo "$outp" | cut -d ',' -f2 | tr -d "[:blank:]")
~/.config/waybar/custom/xtra_menu/xtra_menu.py "$click_x" "$click_y"