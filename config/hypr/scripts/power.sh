#!/bin/bash

case "$1" in
    lock)
        hyprlock
        ;;
    suspend)
        hyprlock &
        sleep 1
        systemctl suspend
        ;;
    logout)
        hyprctl dispatch exit
        ;;
    reboot)
        systemctl reboot
        ;;
    shutdown)
        systemctl poweroff
        ;;
    *)
        echo "Uso: $0 {lock|suspend|logout|reboot|shutdown}"
        exit 1
        ;;
esac
