#!/usr/bin/env bash
# ================================================================
#  dotfiles — Astordna
#  install.sh v2.0 — Professional grade installer
#  Supports: Debian (bare metal) | WSL2
# ================================================================

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="$HOME/.config"
LOCAL_BIN="$HOME/.local/bin"
LOCAL_SHARE="$HOME/.local/share"

# ── ANSI ─────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; MAGENTA='\033[0;35m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

info()    { echo -e "${CYAN}${BOLD}  ❱${NC} $1"; }
success() { echo -e "${GREEN}${BOLD}  ✓${NC} $1"; }
warn()    { echo -e "${YELLOW}${BOLD}  ⚠${NC} $1"; }
error()   { echo -e "${RED}${BOLD}  ✗${NC} $1"; exit 1; }
skip()    { echo -e "${DIM}  · $1 (omitido)${NC}"; }
step()    { echo -e "\n${BLUE}${BOLD}▶ $1${NC}"; }
banner()  {
    echo -e "${MAGENTA}${BOLD}"
    echo "  ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗"
    echo "  ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝"
    echo "  ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗"
    echo "  ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║"
    echo "  ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║"
    echo "  ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝"
    echo -e "${NC}${DIM}  Astordna — Sway / Hyprland environment installer${NC}\n"
}

# ── Helpers ──────────────────────────────────────────────────
has() { command -v "$1" &>/dev/null; }

link() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        warn "Backup: $dst → $dst.bak"
        mv "$dst" "$dst.bak"
    fi
    ln -sf "$src" "$dst"
    success "Enlazado: ${DIM}$dst${NC}"
}

link_dir() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        warn "Backup: $dst → $dst.bak"
        mv "$dst" "$dst.bak"
    fi
    ln -sf "$src" "$dst"
    success "Enlazado (dir): ${DIM}$dst${NC}"
}

apt_install() {
    local pkgs=("$@") to_install=()
    for pkg in "${pkgs[@]}"; do
        dpkg -s "$pkg" &>/dev/null 2>&1 || to_install+=("$pkg")
    done
    if [[ ${#to_install[@]} -gt 0 ]]; then
        info "Instalando: ${to_install[*]}"
        sudo apt-get install -y --no-install-recommends "${to_install[@]}" 2>/dev/null \
            || warn "Algunos paquetes fallaron: ${to_install[*]}"
    else
        skip "Paquetes ya instalados"
    fi
}

ask_choice() {
    local prompt="$1" var="$2"; shift 2
    local opts=("$@")
    echo -e "\n${YELLOW}${BOLD}  ?${NC} ${BOLD}$prompt${NC}"
    for i in "${!opts[@]}"; do
        echo -e "    ${CYAN}$((i+1))${NC}) ${opts[$i]}"
    done
    echo -ne "    ${DIM}Opción [1]:${NC} "
    read -r choice; choice="${choice:-1}"
    eval "$var=\"${opts[$((choice-1))]}\""
}

ask_yn() {
    local prompt="$1" default="${2:-y}"
    echo -ne "${YELLOW}${BOLD}  ?${NC} $prompt ${DIM}[$default]:${NC} "
    read -r answer; answer="${answer:-$default}"
    [[ "$answer" =~ ^[Yy] ]]
}

# ════════════════════════════════════════════════════════════
banner

# Detección automática WSL2
if grep -qi microsoft /proc/version 2>/dev/null; then
    AUTO_ENV="WSL2"
else
    AUTO_ENV="Debian"
fi
info "Entorno detectado automáticamente: ${BOLD}$AUTO_ENV${NC}"

ask_choice "Confirma el entorno:" ENV \
    "Debian (bare metal)" \
    "WSL2"

IS_WSL=false
[[ "$ENV" == *"WSL2"* ]] && IS_WSL=true

ask_choice "Window Manager:" WM \
    "Sway" \
    "Hyprland" \
    "Ambos"

#ask_choice "Terminal:" TERMINAL \
#    "foot (recomendado WSL2)" \
#    "kitty" \
#    "Ambas"

TERMINAL="kitty"

echo -e "\n${BOLD}  Resumen:${NC}"
echo -e "  ${DIM}Entorno:${NC}  ${BOLD}$ENV${NC}"
echo -e "  ${DIM}WM:${NC}       ${BOLD}$WM${NC}"
echo -e "  ${DIM}Terminal:${NC} ${BOLD}$TERMINAL${NC}\n"
ask_yn "¿Continuar?" || { echo "Abortado."; exit 0; }

# ════════════════════════════════════════════════════════════
step "1. Actualizando sistema"

cat << 'EOF' | sudo tee /etc/apt/sources.list
deb http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware

deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware

deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware

deb http://deb.debian.org/debian trixie-backports main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian trixie-backports main contrib non-free non-free-firmware
EOF

sudo apt-get update -q && sudo apt-get upgrade -y -q

# ════════════════════════════════════════════════════════════
step "2. Paquetes base"

BASE_PKGS=(
    zsh zsh-syntax-highlighting zsh-autosuggestions git curl wget unzip
    waybar swaybg dunst rofi wlogout
    grim slurp swappy cliphist
    xdg-desktop-portal-gtk
    pamixer playerctl pavucontrol pulsemixer wireplumber
    nwg-look lxappearance qt5ct qt6ct
    adwaita-qt adwaita-qt6 papirus-icon-theme xcursor-themes
    lsd bat btop htop fastfetch jq feh imagemagick tmux vim
    fonts-firacode fonts-noto-color-emoji fonts-cantarell
    xdotool xclip xsel libnotify-bin
    thunar thunar-archive-plugin
    brightnessctl
)
[[ "$IS_WSL" == false ]] && BASE_PKGS+=(xsettingsd wlsunset seatd)

apt_install "${BASE_PKGS[@]}"

[[ "$WM" == *"Sway"* || "$WM" == "Ambos" ]] && apt_install sway swayidle
[[ "$WM" == *"Hyprland"* || "$WM" == "Ambos" ]] && \
    apt_install hyprland xdg-desktop-portal-hyprland 2>/dev/null || \
    warn "Hyprland no en repos — compila manualmente"

[[ "$TERMINAL" == *"foot"* || "$TERMINAL" == "Ambas" ]] && apt_install foot

if [[ "$TERMINAL" == *"kitty"* || "$TERMINAL" == "Ambas" ]]; then
    if ! has kitty; then
        info "Instalando kitty..."
        curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
        mkdir -p "$LOCAL_BIN"
        ln -sf "$HOME/.local/kitty.app/bin/kitty"  "$LOCAL_BIN/kitty"
        ln -sf "$HOME/.local/kitty.app/bin/kitten" "$LOCAL_BIN/kitten"
        success "Kitty instalado"
    else
        skip "Kitty ya instalado"
    fi
fi

# ════════════════════════════════════════════════════════════
step "3. Oh My Zsh + Powerlevel10k"

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    RUNZSH=no CHSH=no sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    skip "Oh My Zsh ya instalado"
fi

P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
    skip "Powerlevel10k ya instalado"
fi

[[ "$(basename "$SHELL")" != "zsh" ]] && chsh -s "$(which zsh)" "$USER"

# ════════════════════════════════════════════════════════════
step "4. Fuentes — Hack Nerd Font Propo"

FONTS_DIR="$LOCAL_SHARE/fonts"
mkdir -p "$FONTS_DIR"

if [[ ! -d "$FONTS_DIR/HackNerdFont" ]]; then
    HACK_VER="3.3.0"
    TMP_F="$(mktemp -d)"
    info "Descargando Hack Nerd Font v${HACK_VER}..."
    curl -L --progress-bar \
        "https://github.com/ryanoasis/nerd-fonts/releases/download/v${HACK_VER}/Hack.zip" \
        -o "$TMP_F/Hack.zip"
    unzip -q "$TMP_F/Hack.zip" -d "$TMP_F/Hack"
    mkdir -p "$FONTS_DIR/HackNerdFont"
    find "$TMP_F/Hack" -name "*.ttf" -exec cp {} "$FONTS_DIR/HackNerdFont/" \;
    rm -rf "$TMP_F"
    fc-cache -f "$FONTS_DIR" &>/dev/null
    success "Hack Nerd Font instalada"
else
    skip "Hack Nerd Font ya instalada"
fi

# Fuentes adicionales del repo
if [[ -d "$DOTFILES/fonts" && -n "$(ls -A "$DOTFILES/fonts" 2>/dev/null)" ]]; then
    cp -r "$DOTFILES/fonts/"* "$FONTS_DIR/"
    fc-cache -f "$FONTS_DIR" &>/dev/null
    success "Fuentes adicionales del repo instaladas"
fi

# ════════════════════════════════════════════════════════════
step "5. Cursores"

ICONS_DIR="$LOCAL_SHARE/icons"
mkdir -p "$ICONS_DIR"

install_cursor() {
    local name="$1" url="$2"
    if [[ ! -d "$ICONS_DIR/$name" ]]; then
        if [[ -d "$DOTFILES/themes/cursors/$name" ]]; then
            cp -r "$DOTFILES/themes/cursors/$name" "$ICONS_DIR/"
            success "$name instalado desde dotfiles"
        else
            info "Descargando $name..."
            local tmp; tmp="$(mktemp -d)"
            curl -L "$url" -o "$tmp/$name.tar.gz" 2>/dev/null \
                && tar -xzf "$tmp/$name.tar.gz" -C "$ICONS_DIR/" \
                && success "$name descargado" \
                || warn "$name no pudo descargarse — instálalo manualmente en $ICONS_DIR"
            rm -rf "$tmp"
        fi
    else
        skip "$name ya instalado"
    fi
}

install_cursor "Nordic-cursors" \
    "https://github.com/EliverLara/Nordic/releases/latest/download/Nordic-cursors.tar.gz"
install_cursor "Nordzy-cursors" \
    "https://github.com/alvatip/Nordzy-cursors/releases/latest/download/Nordzy-cursors.tar.gz"

# Default cursor
mkdir -p "$ICONS_DIR/default"
cat > "$ICONS_DIR/default/index.theme" << 'EOF'
[Icon Theme]
Name=Default
Inherits=Nordic-cursors
EOF
success "Cursor por defecto: Nordic-cursors"

# ════════════════════════════════════════════════════════════
step "6. Iconos — Papirus-Dark, Breeze, Kora"

apt_install breeze-cursor-theme 2>/dev/null || true

if [[ ! -d "$ICONS_DIR/Kora" ]]; then
    if [[ -d "$DOTFILES/themes/icons/Kora" ]]; then
        cp -r "$DOTFILES/themes/icons/Kora" "$ICONS_DIR/"
        success "Kora instalado desde dotfiles"
    else
        info "Descargando Kora icon theme..."
        tmp="$(mktemp -d)"
        curl -L "https://github.com/bikass/kora/archive/refs/heads/master.tar.gz" \
            -o "$tmp/kora.tar.gz" 2>/dev/null \
            && tar -xzf "$tmp/kora.tar.gz" -C "$tmp/" \
            && find "$tmp" -maxdepth 2 -name "kora*" -type d \
               -exec cp -r {} "$ICONS_DIR/" \; \
            && success "Kora instalado" \
            || warn "Kora no pudo descargarse — instálalo manualmente"
        rm -rf "$tmp"
    fi
else
    skip "Kora ya instalado"
fi

# ════════════════════════════════════════════════════════════
step "7. Wallpaper"

mkdir -p "$HOME/Pictures"
if [[ -f "$DOTFILES/wallpapers/wallpaper.png" ]]; then
    [[ ! -f "$HOME/Pictures/wallpaper.png" ]] \
        && cp "$DOTFILES/wallpapers/wallpaper.png" "$HOME/Pictures/wallpaper.png" \
        && success "Wallpaper copiado" \
        || skip "Wallpaper ya existe"
else
    warn "wallpapers/wallpaper.png no encontrado — añádelo manualmente a ~/Pictures"
fi

# ════════════════════════════════════════════════════════════
step "8. Enlazando configuraciones"

mkdir -p "$LOCAL_BIN"

link "$DOTFILES/shell/zshrc"  "$HOME/.zshrc"
link "$DOTFILES/shell/zshenv" "$HOME/.zshenv"
[[ -f "$DOTFILES/shell/p10k.zsh" ]] \
    && link "$DOTFILES/shell/p10k.zsh" "$HOME/.p10k.zsh" \
    || warn "p10k.zsh no encontrado — ejecuta 'p10k configure' manualmente"

link_dir "$DOTFILES/config/waybar"  "$CFG/waybar"
link_dir "$DOTFILES/config/gtk-3.0" "$CFG/gtk-3.0"
link_dir "$DOTFILES/config/gtk-4.0" "$CFG/gtk-4.0"
link_dir "$DOTFILES/config/qt6ct"   "$CFG/qt6ct"

[[ -d "$DOTFILES/config/dunst" ]] && link_dir "$DOTFILES/config/dunst" "$CFG/dunst"
[[ -d "$DOTFILES/config/rofi"  ]] && link_dir "$DOTFILES/config/rofi"  "$CFG/rofi"

[[ "$TERMINAL" == *"foot"*   || "$TERMINAL" == "Ambas" ]] \
    && [[ -d "$DOTFILES/config/foot" ]] \
    && link_dir "$DOTFILES/config/foot" "$CFG/foot"

[[ "$TERMINAL" == *"kitty"*  || "$TERMINAL" == "Ambas" ]] \
    && link_dir "$DOTFILES/config/kitty" "$CFG/kitty"

if [[ "$WM" == *"Sway"* || "$WM" == "Ambos" ]]; then
    link_dir "$DOTFILES/config/sway" "$CFG/sway"
    install -m 755 "$DOTFILES/scripts/sway-session" "$LOCAL_BIN/sway-session"
    success "sway-session → $LOCAL_BIN"
fi

if [[ "$WM" == *"Hyprland"* || "$WM" == "Ambos" ]]; then
    link_dir "$DOTFILES/config/hypr" "$CFG/hypr"
    install -m 755 "$DOTFILES/scripts/hyprland-session" "$LOCAL_BIN/hyprland-session"
    success "hyprland-session → $LOCAL_BIN"
fi

# ════════════════════════════════════════════════════════════
step "9. Aplicar tema GTK / iconos / cursores"

if has gsettings; then
    gsettings set org.gnome.desktop.interface gtk-theme            "Adwaita-dark"              2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme           "Papirus-Dark"              2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme         "Nordic-cursors"            2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size          24                          2>/dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme         "prefer-dark"               2>/dev/null || true
    gsettings set org.gnome.desktop.interface font-name            "Noto Sans 11"              2>/dev/null || true
    gsettings set org.gnome.desktop.interface monospace-font-name  "HackNerdFontPropo-Regular 11" 2>/dev/null || true
    success "Tema aplicado via gsettings"
fi

# ════════════════════════════════════════════════════════════
step "10. Permisos de scripts"

find "$DOTFILES/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
find "$DOTFILES/config"  -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
success "Permisos aplicados"

grep -q "$LOCAL_BIN" "$HOME/.zshenv" 2>/dev/null \
    || echo "export PATH=\"$LOCAL_BIN:\$PATH\"" >> "$HOME/.zshenv"

# ════════════════════════════════════════════════════════════
if [[ "$IS_WSL" == false ]]; then
    step "11. Ly — Display Manager"
    if has ly || dpkg -s ly &>/dev/null 2>&1; then
        [[ -f "$DOTFILES/ly/config.ini" ]] \
            && sudo cp "$DOTFILES/ly/config.ini" /etc/ly/config.ini \
            && sudo systemctl enable ly 2>/dev/null \
            && success "Ly configurado y habilitado" \
            || warn "ly/config.ini no encontrado"
    else
        warn "Ly no instalado — instálalo y re-ejecuta el installer"
    fi
else
    step "11. Ajustes WSL2"
    LAUNCHER="$CFG/waybar/custom/xtra_menu/xtra_menu_launcher.sh"
    if [[ "$WM" == *"Sway"* && -f "$LAUNCHER" ]]; then
        sed -i 's|hyprctl cursorpos|echo "0 0"|g' "$LAUNCHER" 2>/dev/null || true
        info "xtra_menu_launcher adaptado para Sway/WSL2"
    fi
    info "Recuerda añadir '\"interface\": \"eth0\"' a network_ip.json"
fi

cat << 'EOF' | sudo tee /usr/share/wayland-sessions/hyprland.desktop
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=/usr/local/bin/start-hyprland
EOF

# =═══════════════════════════════════════════════════════════
# Hyprland Building
if [[ "$WM" == *"Hyprland"* || "$WM" == "Ambos" ]]; then
    if ! has hyprland; then
        info "Hyprland no encontrado — compila manualmente siguiendo las instrucciones oficiales"
        echo -e "  ${YELLOW}

# ════════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}  ✓ Instalación completada${NC}"
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\n  ${DIM}Entorno:${NC}  ${BOLD}$ENV${NC}"
echo -e "  ${DIM}WM:${NC}       ${BOLD}$WM${NC}"
echo -e "  ${DIM}Terminal:${NC} ${BOLD}$TERMINAL${NC}\n"
[[ "$IS_WSL" == true ]] \
    && echo -e "  ${CYAN}▶ Arrancar:${NC} ${BOLD}sway-session${NC} / ${BOLD}hyprland-session${NC}" \
    || echo -e "  ${CYAN}▶ Reinicia y selecciona sesión en Ly${NC}"
echo -e "\n  ${YELLOW}⚠ Post-instalación:${NC}"
echo -e "  ${DIM}·${NC} Primera vez: ejecuta ${BOLD}p10k configure${NC}"
echo -e "  ${DIM}·${NC} Añade wallpaper: ${BOLD}~/Pictures/wallpaper.png${NC}"
echo -e "  ${DIM}·${NC} Recarga zsh: ${BOLD}exec zsh${NC}\n"
