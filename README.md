# dotfiles — Aderfi

<div align="center">

![Debian](https://img.shields.io/badge/Debian-Trixie-red?style=flat-square&logo=debian)
![WSL2](https://img.shields.io/badge/WSL2-Compatible-blue?style=flat-square&logo=windows)
![Sway](https://img.shields.io/badge/Sway-1.10-brightgreen?style=flat-square)
![Hyprland](https://img.shields.io/badge/Hyprland-0.53-purple?style=flat-square)
![Waybar](https://img.shields.io/badge/Waybar-Custom-orange?style=flat-square)

</div>

Personal desktop environment based on **Hyprland**. Using **Sway** for WSL2. Both with Waybar and custom modules.

**Zsh + Oh My Zsh + Powerlevel10k.**

Compatible w/ **Debian** y **WSL2**.

---

## Componentes

| Categoría       | Herramienta                         |
| --------------- | ----------------------------------- |
| WM              | Sway / Hyprland                     |
| Bar             | Waybar (custom modules + xtra_menu) |
| Shell           | Zsh + Oh My Zsh + Powerlevel10k     |
| Terminal        | Kitty                               |
| Launcher        | Rofi                                |
| Notificaciones  | Dunst                               |
| Wallpaper       | swaybg                              |
| File Manager    | Thunar                              |
| GTK Theme       | Adwaita-dark                        |
| Icon Theme      | Papirus-Dark / Breeze / Kora        |
| Cursor (X)      | Nordic-cursors                      |
| Cursor (Hypr)   | Nordzy-cursors                      |
| Main Font       | Hack Nerd Font Propo                |
| Session Manager | Ly (Custom config)                  |
| Qt Theme        | Adwaita-Dark (qt6ct)                |

---

## [Structure](docs/PROJECT_STRUCTURE.md)

## Instalación rápida

```bash
git clone https://github.com/Aderfi/dotfiles_Aderfi.git ~/.dotfiles
cd ~/.dotfiles
chmod +x install.sh
./install.sh
```

Auto detection of env. Debian/WSL2:

- **Entorno**: Debian / WSL2
- **WM**: Sway, Hyprland, Both
- **Terminal**: kitty (foot by default when installing Hyprland)

### What does?

1. Set up sources deb & deb-src for main, security, updates and backports
   
       With the next suites: main contrib non-free non-free-firmware
   
   Update system and upgrade.
   
   ### Installs

2. Install base packages (waybar, dunst, rofi, wlogout, etc.)

3. Window Manager

4. Terminal

5. Zsh + Oh My Zsh + Powerlevel10k

6. Download & Install Hack Nerd Font Propo** 

7. Cursors Nordic + Nordzy

8. Icon-themes Papirus-Dark, Breeze, Kora

9. Copy wallpaper

10. Symlinks for all configs

11. Appy themes with gsettings

12. Configure Ly session manager
    
    1. It is possible you have to remove sddm

13. **A**

## Pack.sh

```bash
cd ~/.dotfiles
./pack.sh
git commit -m "Update dotfiles $(date +%Y-%m-%d)"
git push
```

pack.sh will automatically copy all files corresponding to the configuration to its ubication. If executed in an empty dir, will iterate over all the corresponding configuration present and copy into de dir so it can be compressed lately.

Also useful for updates.

---

## Notas WSL2

- XWayland NOT WORKING on WSLg
- Apps X11 use XWayland de WSLg directly (Weston)
- `battery` module of Waybar disabled en WSL2. 
  - Activate if running on laptop
- Add `"interface": "eth0"` to `network_ip.json` to avoid the RFKILL error
- Rounded borders not available in WSL2 (SwayFX requiere acceso DRM directo)
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

## External Libs (auto downloaded)

| Recurso        | Fuente                            |
| -------------- | --------------------------------- |
| Hack Nerd Font | github.com/ryanoasis/nerd-fonts   |
| Nordic cursors | github.com/EliverLara/Nordic      |
| Nordzy cursors | github.com/alvatip/Nordzy-cursors |
| Kora icons     | github.com/bikass/kora            |
| Powerlevel10k  | github.com/romkatv/powerlevel10k  |
| Oh My Zsh      | github.com/ohmyzsh/ohmyzsh        |