#!/usr/bin/env bash
# ================================================================
#  dotfiles — Astordna
#  pack.sh — Empaqueta los dotfiles desde el sistema actual
#  Ejecutar en el sistema fuente (portátil Debian)
# ================================================================

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="$HOME/.config"

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

info()    { echo -e "${CYAN}${BOLD}  ❱${NC} $1"; }
success() { echo -e "${GREEN}${BOLD}  ✓${NC} $1"; }
warn()    { echo -e "${YELLOW}${BOLD}  ⚠${NC} $1"; }

cp_safe() {
    local src="$1" dst="$2"
    if [[ -e "$src" ]]; then
        mkdir -p "$(dirname "$dst")"
        cp -r "$src" "$dst"
        success "Copiado: ${DIM}$dst${NC}"
    else
        warn "No encontrado: $src"
    fi
}

echo -e "\n${BOLD}  Empaquetando dotfiles...${NC}\n"

# ── Sway ────────────────────────────────────────────────────
info "Sway..."
mkdir -p "$DOTFILES/config/sway/scripts"
cp_safe "$CFG/sway/config"          "$DOTFILES/config/sway/config"
find "$CFG/sway/scripts/" -name "*.sh" -exec cp {} "$DOTFILES/config/sway/scripts/" \; 2>/dev/null || true

# ── Hyprland ────────────────────────────────────────────────
info "Hyprland..."
mkdir -p "$DOTFILES/config/hypr/scripts"
cp_safe "$CFG/hypr/hyprland.conf"   "$DOTFILES/config/hypr/hyprland.conf"
find "$CFG/hypr/scripts/" -name "*.sh" -exec cp {} "$DOTFILES/config/hypr/scripts/" \; 2>/dev/null || true

# ── Waybar ──────────────────────────────────────────────────
info "Waybar..."
mkdir -p "$DOTFILES/config/waybar/conf/modules"
mkdir -p "$DOTFILES/config/waybar/custom/xtra_menu"
cp_safe "$CFG/waybar/config.jsonc"          "$DOTFILES/config/waybar/config.jsonc"
cp_safe "$CFG/waybar/style.css"             "$DOTFILES/config/waybar/style.css"
cp_safe "$CFG/waybar/colors.css"            "$DOTFILES/config/waybar/colors.css"
cp_safe "$CFG/waybar/launch.sh"             "$DOTFILES/config/waybar/launch.sh"
find "$CFG/waybar/conf/modules/" -name "*.json" \
    -exec cp {} "$DOTFILES/config/waybar/conf/modules/" \; 2>/dev/null || true
find "$CFG/waybar/custom/xtra_menu/" -type f \
    -exec cp {} "$DOTFILES/config/waybar/custom/xtra_menu/" \; 2>/dev/null || true

# ── Kitty ───────────────────────────────────────────────────
info "Kitty..."
mkdir -p "$DOTFILES/config/kitty"
cp_safe "$CFG/kitty/kitty.conf"  "$DOTFILES/config/kitty/kitty.conf"
cp_safe "$CFG/kitty/color.ini"   "$DOTFILES/config/kitty/color.ini"

# ── Foot ────────────────────────────────────────────────────
info "Foot..."
[[ -d "$CFG/foot" ]] && cp_safe "$CFG/foot" "$DOTFILES/config/foot" || true

# ── Dunst ───────────────────────────────────────────────────
info "Dunst..."
[[ -d "$CFG/dunst" ]] && cp_safe "$CFG/dunst" "$DOTFILES/config/dunst" || true

# ── Rofi ────────────────────────────────────────────────────
info "Rofi..."
[[ -d "$CFG/rofi" ]] && cp_safe "$CFG/rofi" "$DOTFILES/config/rofi" || true

# ── GTK ─────────────────────────────────────────────────────
info "GTK..."
mkdir -p "$DOTFILES/config/gtk-3.0" "$DOTFILES/config/gtk-4.0"
for f in gtk.css gtk-mine.css settings.ini; do
    cp_safe "$CFG/gtk-3.0/$f" "$DOTFILES/config/gtk-3.0/$f"
done
cp_safe "$CFG/gtk-4.0/gtk.css" "$DOTFILES/config/gtk-4.0/gtk.css"

# ── Qt6ct ───────────────────────────────────────────────────
info "Qt6ct..."
mkdir -p "$DOTFILES/config/qt6ct"
cp_safe "$CFG/qt6ct/qt6ct.conf" "$DOTFILES/config/qt6ct/qt6ct.conf"

# ── Zsh ─────────────────────────────────────────────────────
info "Zsh..."
mkdir -p "$DOTFILES/shell"
cp_safe "$HOME/.zshrc"    "$DOTFILES/shell/zshrc"
cp_safe "$HOME/.zshenv"   "$DOTFILES/shell/zshenv"
cp_safe "$HOME/.p10k.zsh" "$DOTFILES/shell/p10k.zsh"

# ── Session wrappers ─────────────────────────────────────────
info "Session wrappers..."
mkdir -p "$DOTFILES/scripts"
cp_safe "$HOME/.local/bin/sway-session"       "$DOTFILES/scripts/sway-session"
cp_safe "/usr/local/bin/hyprland-session"   "$DOTFILES/scripts/hyprland-session"

# ── Ly ──────────────────────────────────────────────────────
info "Ly..."
mkdir -p "$DOTFILES/ly"
sudo cp /etc/ly/config.ini "$DOTFILES/ly/config.ini" 2>/dev/null \
    && success "Copiado: $DOTFILES/ly/config.ini" \
    || warn "Ly config no encontrada"

# ── Wallpaper placeholder ────────────────────────────────────
info "Wallpaper..."
mkdir -p "$DOTFILES/wallpapers"
if [[ ! -f "$DOTFILES/wallpapers/wallpaper.png" ]]; then
    if command -v convert &>/dev/null; then
        convert -size 1920x1080 xc:#1d1f21 \
            -font "DejaVu-Sans" -pointsize 36 \
            -fill "#616161" -gravity center \
            -annotate 0 "Add your wallpaper here\nwallpapers/wallpaper.png" \
            "$DOTFILES/wallpapers/wallpaper.png" 2>/dev/null \
            && success "Wallpaper placeholder creado" \
            || touch "$DOTFILES/wallpapers/wallpaper.png"
    else
        touch "$DOTFILES/wallpapers/wallpaper.png"
        warn "Añade tu wallpaper como wallpapers/wallpaper.png"
    fi
fi

# ── Permisos ─────────────────────────────────────────────────
info "Aplicando permisos..."
chmod +x "$DOTFILES/install.sh" "$DOTFILES/pack.sh"
find "$DOTFILES/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
find "$DOTFILES/config"  -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# ── Git setup ────────────────────────────────────────────────
if [[ ! -d "$DOTFILES/.git" ]]; then
    echo ""
    info "Inicializando repositorio git..."
    cd "$DOTFILES"
    git init
    git add .
    echo ""
    echo -e "${CYAN}${BOLD}  Siguiente:${NC}"
    echo "    git remote add origin https://github.com/TU_USUARIO/dotfiles.git"
    echo "    git commit -m 'Initial dotfiles'"
    echo "    git push -u origin main"
else
    cd "$DOTFILES"
    git add .
    echo ""
    info "Archivos añadidos al staging. Para commitear:"
    echo "    git commit -m 'Update dotfiles $(date +%Y-%m-%d)'"
    echo "    git push"
fi

echo ""
success "¡Dotfiles empaquetados correctamente en $DOTFILES"