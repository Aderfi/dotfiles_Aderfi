#!/usr/bin/env bash
# ================================================================
#  dotfiles — Astordna
#  pack.sh — Empaqueta los dotfiles desde el sistema actual
#  Ejecutar en el sistema fuente (portátil Debian)
#
#  Uso: ./pack.sh [-n|--dry-run] [--no-git] [-h|--help]
# ================================================================

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
REPO_CFG="$DOTFILES/config"

DRY_RUN=false
DO_GIT=true

usage() {
    cat <<EOF
Uso: $(basename "$0") [opciones]

  -n, --dry-run   Muestra qué se copiaría sin tocar nada
      --no-git    No hace 'git add' al terminar
  -h, --help      Muestra esta ayuda
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run) DRY_RUN=true ;;
        --no-git)     DO_GIT=false ;;
        -h|--help)    usage; exit 0 ;;
        *)            echo "Opción desconocida: $1"; usage; exit 1 ;;
    esac
    shift
done

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
BLUE='\033[0;34m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

info()    { echo -e "${CYAN}${BOLD}  ❱${NC} $1"; }
success() { echo -e "${GREEN}${BOLD}  ✓${NC} $1"; }
warn()    { echo -e "${YELLOW}${BOLD}  ⚠${NC} $1"; }
skip()    { echo -e "${DIM}  · $1${NC}"; }
step()    { echo -e "\n${BLUE}${BOLD}▶ $1${NC}"; }

COPIED=0; MISSING=0

# Excluidos siempre al copiar directorios
COMMON_EXCLUDES=(
    '*.bak' '*.back' '*.back.*' '*.old' '*~' '*.swp' '*.swo'
    '*.log' '*.tar.gz' '*.zip'
    '__pycache__/' '*.pyc' '.git/' 'node_modules/'
)

# ── Helpers ──────────────────────────────────────────────────

# Copia un archivo suelto. Uso: pack_file <src> <dst-relativo-al-repo>
pack_file() {
    local src="$1" dst="$DOTFILES/$2"
    if [[ ! -f "$src" ]]; then
        skip "No encontrado: ${src/#$HOME/\~}"
        MISSING=$((MISSING + 1))
        return 0
    fi
    if $DRY_RUN; then
        echo -e "    ${DIM}[dry-run]${NC} ${src/#$HOME/\~} → $2"
    else
        mkdir -p "$(dirname "$dst")"
        cp -p "$src" "$dst"
    fi
    success "$2"
    COPIED=$((COPIED + 1))
}

# Espeja un directorio (rsync --delete: el repo refleja el sistema).
# Uso: pack_dir <src-dir> <dst-relativo-al-repo> [patrones a excluir...]
pack_dir() {
    local src="$1" rel="$2"; shift 2
    local dst="$DOTFILES/$rel"
    if [[ ! -d "$src" ]]; then
        skip "No encontrado: ${src/#$HOME/\~}/"
        MISSING=$((MISSING + 1))
        return 0
    fi
    # --copy-unsafe-links: symlinks que apuntan fuera (p. ej. a /usr/share/themes)
    # se copian como archivo real para que el repo sea portable.
    local args=(-a --copy-unsafe-links --delete --delete-excluded)
    $DRY_RUN && args+=(-n --itemize-changes)
    local pat
    for pat in "${COMMON_EXCLUDES[@]}" "$@"; do
        args+=(--exclude="$pat")
    done
    $DRY_RUN || mkdir -p "$dst"

    # Symlinks rotos: se excluyen (y se avisa) para que rsync no aborte.
    local broken
    while IFS= read -r -d '' broken; do
        warn "Symlink roto omitido: ${broken/#$HOME/\~}"
        args+=(--exclude="/${broken#"$src"/}")
    done < <(find "$src" -xtype l -print0 2>/dev/null)

    local rc=0
    if $DRY_RUN; then
        local line
        rsync "${args[@]}" "$src/" "$dst/" | while IFS= read -r line; do
            echo -e "    ${DIM}[dry-run]${NC} $line"
        done || rc=$?
    else
        rsync "${args[@]}" "$src/" "$dst/" || rc=$?
    fi
    if (( rc != 0 )); then
        warn "rsync terminó con código $rc en $rel/ (revisa los mensajes de arriba)"
        return 0
    fi
    success "$rel/"
    COPIED=$((COPIED + 1))
}

command -v rsync &>/dev/null || { echo "rsync es necesario: sudo apt install rsync"; exit 1; }

echo -e "\n${BOLD}  Empaquetando dotfiles${NC} ${DIM}→ $DOTFILES${NC}"
$DRY_RUN && warn "Modo dry-run: no se modifica nada"

# ════════════════════════════════════════════════════════════
step "Shell (zsh / bash / login)"
pack_file "$HOME/.zshrc"     shell/zshrc
pack_file "$HOME/.zshenv"    shell/zshenv
pack_file "$HOME/.zprofile"  shell/zprofile
pack_file "$HOME/.p10k.zsh"  shell/p10k.zsh
pack_file "$HOME/.profile"   shell/profile      # arranca uwsm/Hyprland en login TTY
pack_file "$HOME/.bashrc"    shell/bashrc

# ════════════════════════════════════════════════════════════
step "Git"
pack_file "$HOME/.gitconfig"      git/gitconfig
pack_file "$CFG/git/ignore"       config/git/ignore
# NUNCA: ~/.git-credentials

# ════════════════════════════════════════════════════════════
step "Hyprland"
# hyprland.conf es monolítico: conf/ son restos de ML4W y no se usan.
pack_dir "$CFG/hypr" config/hypr \
    'conf/' '*.conf.back*' 'mmm.txt' 'hpr_BACKUP/'

# ════════════════════════════════════════════════════════════
step "Sway"
pack_dir "$CFG/sway" config/sway

# ════════════════════════════════════════════════════════════
step "Sesión Wayland (uwsm / env / portales)"
pack_dir "$CFG/uwsm"               config/uwsm 'default-id'
pack_dir "$CFG/environment.d"      config/environment.d
pack_dir "$CFG/xdg-desktop-portal" config/xdg-desktop-portal
pack_file /usr/local/bin/hyprland-session scripts/hyprland-session
pack_file "$HOME/.local/bin/sway-session" scripts/sway-session

# ════════════════════════════════════════════════════════════
step "Waybar"
# themes/ = temas ML4W descargados (no usados por config.jsonc)
pack_dir "$CFG/waybar" config/waybar 'themes/' 'old_*'

# ════════════════════════════════════════════════════════════
step "Notificaciones / launcher / lock"
pack_dir "$CFG/swaync" config/swaync
pack_dir "$CFG/dunst"  config/dunst
pack_dir "$CFG/wofi"   config/wofi
pack_dir "$CFG/rofi"   config/rofi

# ════════════════════════════════════════════════════════════
step "Terminales"
pack_dir "$CFG/kitty" config/kitty
pack_dir "$CFG/foot"  config/foot

# ════════════════════════════════════════════════════════════
step "Herramientas CLI"
pack_dir "$CFG/lsd"       config/lsd
pack_dir "$CFG/fastfetch" config/fastfetch
pack_dir "$CFG/btop"      config/btop
pack_dir "$CFG/micro"     config/micro 'backups/' 'buffers/' 'plug/'
pack_dir "$CFG/cava"      config/cava

# ════════════════════════════════════════════════════════════
step "Tema GTK / Qt / cursores / fuentes"
pack_dir  "$CFG/gtk-3.0"    config/gtk-3.0 'bookmarks'   # bookmarks = rutas personales
pack_dir  "$CFG/gtk-4.0"    config/gtk-4.0 'bookmarks'
pack_dir  "$CFG/qt5ct"      config/qt5ct
pack_dir  "$CFG/qt6ct"      config/qt6ct
pack_dir  "$CFG/Kvantum"    config/Kvantum
pack_dir  "$CFG/nwg-look"   config/nwg-look
pack_dir  "$CFG/xsettingsd" config/xsettingsd
pack_dir  "$CFG/fontconfig" config/fontconfig
pack_file "$HOME/.icons/default/index.theme" icons/default/index.theme

# ════════════════════════════════════════════════════════════
step "XDG"
pack_file "$CFG/mimeapps.list"  config/mimeapps.list
pack_file "$CFG/user-dirs.dirs" config/user-dirs.dirs

# ════════════════════════════════════════════════════════════
step "Ly (display manager)"
if [[ -r /etc/ly/config.ini ]]; then
    pack_file /etc/ly/config.ini ly/config.ini
elif [[ -f /etc/ly/config.ini ]] && ! $DRY_RUN; then
    sudo cat /etc/ly/config.ini > "$DOTFILES/ly/config.ini" \
        && success "ly/config.ini (sudo)" || warn "No se pudo leer /etc/ly/config.ini"
else
    skip "No encontrado: /etc/ly/config.ini"
fi

# ════════════════════════════════════════════════════════════
if ! $DRY_RUN; then
    step "Permisos"
    find "$DOTFILES/scripts" "$DOTFILES/config" -type f \
        \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} + 2>/dev/null || true
    chmod +x "$DOTFILES"/scripts/*-session "$DOTFILES/install.sh" "$DOTFILES/pack.sh" 2>/dev/null || true
    success "Scripts ejecutables"
fi

# ════════════════════════════════════════════════════════════
step "Comprobando secretos"
SECRET_RE='(gh[pousr]_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|(token|secret|passw(or)?d|api_?key)[A-Za-z_]*[[:space:]]*[=:][[:space:]]*["'"'"']?[A-Za-z0-9_-]{16,})'
SECRETS_FOUND=false
scan_dirs=()
for d in shell config git scripts ly; do [[ -d "$DOTFILES/$d" ]] && scan_dirs+=("$DOTFILES/$d"); done
hits=$(command grep -rIniE "$SECRET_RE" "${scan_dirs[@]}" 2>/dev/null || true)
if [[ -n "$hits" ]]; then
    SECRETS_FOUND=true
    warn "${RED}${BOLD}Posibles secretos en archivos empaquetados:${NC}"
    echo "$hits" | sed "s|^$DOTFILES/|      |" | cut -c1-140
    warn "Muévelos a un archivo no versionado (p. ej. ~/.zshrc.local) y vuelve a empaquetar."
else
    success "Nada sospechoso"
fi

# ════════════════════════════════════════════════════════════
echo ""
echo -e "  ${BOLD}Resumen:${NC} ${GREEN}$COPIED copiados${NC}, ${DIM}$MISSING no presentes en este sistema${NC}"

if $DRY_RUN || ! $DO_GIT; then
    exit 0
fi

cd "$DOTFILES"
if [[ ! -d .git ]]; then
    info "Inicializando repositorio git..."
    git init -q
fi

if $SECRETS_FOUND; then
    warn "No se hace 'git add' porque hay posibles secretos. Revisa y ejecuta 'git add' a mano."
    exit 1
fi

git add -A
echo ""
info "Cambios en staging:"
git status --short | sed 's/^/    /'
echo ""
echo "    git commit -m 'Update dotfiles $(date +%Y-%m-%d)' && git push"
