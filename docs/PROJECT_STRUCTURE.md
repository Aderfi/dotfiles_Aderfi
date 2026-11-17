#### Structure

```
dotfiles/
├── install.sh                      # Installer 
├── pack.sh                         # Packer -- more info below
├── README.md
│
├── config/
│   ├── sway/
│   │   ├── config                  # Sway Config
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
│   │   ├── conf/modules/           # JSON Modules for waybar
│   │   │   ├── battery.json
│   │   │   ├── date.json
│   │   │   ├── logo.json
│   │   │   ├── network_ip.json
│   │   │   ├── status.json
│   │   │   ├── sysmenu.json
│   │   │   ├── workspaces.json
│   │   │   └── xtra_func.json
│   │   └── custom/
│   │       └── xtra_menu/          # Custom PopUp-Menu PyGTK
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
│   ├── logo.png               # Logo/Little image for Kitty
│   └── wallpaper.png          # Wallpaper.
└── ly/
    └── config.ini                  # Config Ly (Custom Ly Config)
```
