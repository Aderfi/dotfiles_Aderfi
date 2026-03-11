# dotfiles — Aderfi

<div align="center">

![Debian](https://img.shields.io/badge/Debian-Trixie-red?style=flat-square&logo=debian)
![WSL2](https://img.shields.io/badge/WSL2-Compatible-blue?style=flat-square&logo=windows)
![Sway](https://img.shields.io/badge/Sway-1.10-brightgreen?style=flat-square)
![Hyprland](https://img.shields.io/badge/Hyprland-0.53-purple?style=flat-square)
![Waybar](https://img.shields.io/badge/Waybar-Custom-orange?style=flat-square)

</div>

Entorno personal de escritorio basado en **Sway** / **Hyprland** con Waybar custom,
Zsh + Oh My Zsh + Powerlevel10k. Compatible con **Debian bare metal** y **WSL2**.

---

## Instalación rápida

```bash
git clone https://github.com/TU_USUARIO/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
chmod +x install.sh
./install.sh
```

El script detecta automáticamente si estás en WSL2 o bare metal y pregunta:
- **Entorno**: Debian / WSL2
- **WM**: Sway, Hyprland o ambos
- **Terminal**: foot, kitty o ambas

### Lo que hace el installer

1. Actualiza el sistema
2. Instala paquetes base (waybar, dunst, rofi, wlogout, etc.)
3. Instala el WM seleccionado
4. Instala la terminal seleccionada
5. Instala Oh My Zsh + Powerlevel10k
6. Descarga e instala **Hack Nerd Font Propo** automáticamente
7. Instala cursores Nordic + Nordzy
8. Instala iconos Papirus-Dark, Breeze, Kora
9. Copia el wallpaper
10. Crea symlinks de todas las configuraciones
11. Aplica temas via gsettings
12. Configura Ly (solo bare metal)

---

## Empaquetar desde sistema fuente

Para actualizar el dotfiles desde tu portátil/máquina principal:

```bash
cd ~/.dotfiles
./pack.sh
git commit -m "Update dotfiles $(date +%Y-%m-%d)"
git push
```

---

## Notas WSL2

- XWayland no funciona en modo compositor anidado sobre WSLg
- Apps X11 usan el XWayland de WSLg directamente
- El módulo `battery` de Waybar está desactivado en WSL2
- Añade `"interface": "eth0"` a `network_ip.json` para evitar el error RFKILL
- Bordes redondeados no disponibles (SwayFX requiere acceso DRM directo)
- Arranque: `sway-session` o `hyprland-session` desde la terminal WSL2

---

## Post-instalación

```bash
# Primera vez — configurar prompt
p10k configure

# Recargar shell
exec zsh

# Añadir wallpaper
cp ~/tu-wallpaper.png ~/Pictures/wallpaper.png
```

---

## Componentes

| Categoría        | Herramienta                          |
|------------------|--------------------------------------|
| WM               | Sway / Hyprland                      |
| Bar              | Waybar (custom modules + xtra_menu)  |
| Shell            | Zsh + Oh My Zsh + Powerlevel10k      |
| Terminal         | Kitty / Foot                         |
| Launcher         | Rofi                                 |
| Notificaciones   | Dunst                                |
| Wallpaper        | swaybg                               |
| File Manager     | Thunar                               |
| GTK Theme        | Adwaita-dark                         |
| Icon Theme       | Papirus-Dark / Breeze / Kora         |
| Cursor (X)       | Nordic-cursors                       |
| Cursor (Hypr)    | Nordzy-cursors                       |
| Fuente principal | Hack Nerd Font Propo                 |
| Display Manager  | Ly (solo bare metal)                 |
| Qt Theme         | Adwaita-Dark (qt6ct)                 |

---

## Estructura

```
dotfiles/
├── install.sh                      # Installer principal
├── pack.sh                         # Empaquetador desde sistema fuente
├── README.md
│
├── config/
│   ├── sway/
│   │   ├── config                  # Configuración Sway
│   │   └── scripts/
│   │       └── workspace_toggle.sh
│   │
│   ├── hypr/
│   │   ├── hyprland.conf
│   │   └── scripts/
│   │       └── workspace_toggle.sh
│   │
│   ├── waybar/
│   │   ├── config.jsonc
│   │   ├── style.css
│   │   ├── colors.css
│   │   ├── launch.sh
│   │   ├── conf/modules/           # Módulos JSON individuales
│   │   │   ├── battery.json
│   │   │   ├── date.json
│   │   │   ├── logo.json
│   │   │   ├── network_ip.json
│   │   │   ├── status.json
│   │   │   ├── sysmenu.json
│   │   │   ├── workspaces.json
│   │   │   └── xtra_func.json
│   │   └── custom/
│   │       └── xtra_menu/          # Menú custom Python/GTK
│   │           ├── xtra_menu.py
│   │           ├── xtra_menu.xml
│   │           ├── xtra_menu.css
│   │           └── xtra_menu_launcher.sh
│   │
│   ├── kitty/
│   │   ├── kitty.conf
│   │   └── color.ini
│   │
│   ├── foot/                       # Config foot terminal
│   ├── dunst/                      # Notificaciones
│   ├── rofi/                       # Launcher
│   ├── gtk-3.0/
│   │   ├── gtk.css
│   │   ├── gtk-mine.css
│   │   └── settings.ini
│   ├── gtk-4.0/
│   │   └── gtk.css
│   └── qt6ct/
│       └── qt6ct.conf
│
├── shell/
│   ├── zshrc                       # ~/.zshrc
│   ├── zshenv                      # ~/.zshenv
│   └── p10k.zsh                    # ~/.p10k.zsh
│
├── scripts/
│   ├── sway-session                # Wrapper WSL2 + bare metal
│   └── hyprland-session            # Wrapper WSL2 + bare metal
│
├── fonts/                          # Fuentes adicionales (opcional)
├── themes/
│   ├── cursors/
│   │   ├── Nordic-cursors/         # Xcursor (GTK/Sway)
│   │   └── Nordzy-cursors/         # Hyprcursor (Hyprland)
│   └── icons/
│       └── Kora/                   # Kora icon theme (opcional)
│
├── wallpapers/
│   └── wallpaper.png               # ⚠ Añadir manualmente
│
└── ly/
    └── config.ini                  # Config Ly (solo bare metal)
```

---

## Dependencias externas (descarga automática)

| Recurso          | Fuente                                          |
|------------------|-------------------------------------------------|
| Hack Nerd Font   | github.com/ryanoasis/nerd-fonts                 |
| Nordic cursors   | github.com/EliverLara/Nordic                    |
| Nordzy cursors   | github.com/alvatip/Nordzy-cursors               |
| Kora icons       | github.com/bikass/kora                          |
| Powerlevel10k    | github.com/romkatv/powerlevel10k                |
| Oh My Zsh        | github.com/ohmyzsh/ohmyzsh                      |
