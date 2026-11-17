#!/bin/bash
# Matar instancias previas
#!/bin/bash
killall waybar
sleep 0.2

waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css &&
waybar -c ~/.config/waybar/config-bottom.jsonc -s ~/.config/waybar/style-bottom.css &
