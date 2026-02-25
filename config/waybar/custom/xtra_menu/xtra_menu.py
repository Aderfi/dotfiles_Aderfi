#!/usr/bin/env python3
# ══════════════════════════════════════════════════════════════════════════════
# XTRA MENU — Script principal
# Compatible: GTK 3.20+  ·  Wayland/Hyprland  ·  Python 3.10+
#
# Arquitectura CSS para toggles (100 % gestionada desde Python):
#
#   Clase estática  — añadida una sola vez en _connect_signals:
#     .btn-bluetooth   .btn-nightlight   .btn-airplane
#
#   Clase de estado — añadida/quitada en _apply_toggle_style:
#     .btn-bluetooth--active   .btn-nightlight--active   .btn-airplane--active
#
# El CSS NUNCA usa :checked ni selectores compuestos con IDs.
# ══════════════════════════════════════════════════════════════════════════════

import json
import os
import subprocess
import sys
from pathlib import Path

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, GLib, Gtk  # noqa: E402

# ──────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN — edita aquí, sin tocar el resto del código
# ──────────────────────────────────────────────────────────────────────────────

# Iconos Nerd Font para cada toggle: (inactivo, activo)
TOGGLE_ICONS: dict[str, tuple[str, str]] = {
    "btn_2": ("󰂲", ""),  # Bluetooth:    off / on
    "btn_6": ("󱩌", "󰖔"),  # Luz nocturna: off / on
    "btn_8": ("󰀝", "󱄙"),  # Modo avión:   off / on
}

# Clase CSS estática y clase de estado activo para cada toggle
TOGGLE_CSS: dict[str, tuple[str, str]] = {
    #  btn_id      clase-base           clase-activa
    "btn_2": ("btn-bluetooth",  "btn-bluetooth--active"),
    "btn_6": ("btn-nightlight", "btn-nightlight--active"),
    "btn_8": ("btn-airplane",   "btn-airplane--active"),
}

# Comandos para botones normales (clic izquierdo)
LEFT_CLICK_NORMAL: dict[str, list[str]] = {
    "btn_1": ["firefox"],               # Browser
    "btn_3": ["kitty"],                 # Terminal
    "btn_4": ["code", "--new-window"],  # Editor
    "btn_5": ["spotify"],               # Música
    "btn_7": ["gnome-control-center"],  # Ajustes
    "btn_9": ["wlogout"],               # Logout
}

# Comandos para clic derecho — botones normales (None = sin acción)
RIGHT_CLICK_NORMAL: dict[str, list[str] | None] = {
    "btn_1": None,  # ej: ["firefox", "--preferences"]
    "btn_3": None,  # ej: ["kitty", "--class", "floating"]
    "btn_4": None,  # ej: ["code", "--new-window"]
    "btn_5": None,  # ej: ["spotify", "--show-console"]
    "btn_7": None,  # ej: ["gnome-control-center", "display"]
    "btn_9": None,  # ej: ["wlogout", "-p", "fadeout"]
}

# Comandos para clic derecho — toggles (abrir app de configuración del servicio)
RIGHT_CLICK_TOGGLE: dict[str, list[str] | None] = {
    "btn_2": None,  # ej: ["blueman-manager"]
    "btn_6": None,  # ej: ["gnome-control-center", "display"]
    "btn_8": None,  # ej: ["nm-connection-editor"]
}


# ──────────────────────────────────────────────────────────────────────────────
# CLASE PRINCIPAL
# ──────────────────────────────────────────────────────────────────────────────

class XtraMenu:
    """Popup menu GTK3 para Waybar / Hyprland."""

    # ── Inicialización ────────────────────────────────────────────────────────

    def __init__(self, x: int, y: int) -> None:
        self.click_x = int(x)
        self.click_y = int(y)

        cfg_dir = Path("~/.config/waybar/custom/xtra_menu").expanduser()
        self._ui_file  = cfg_dir / "xtra_menu.xml"
        self._css_file = cfg_dir / "xtra_menu.css"

        # Guardamos los handler-ids para bloquearlos de forma segura
        # Estructura: { btn_id: handler_id }
        self._toggle_handler_ids: dict[str, int] = {}
        # Ídem para los sliders
        self._slider_handler_ids: dict[str, int] = {}

        self._builder = self._load_ui()

        self.window: Gtk.Window = self._builder.get_object("main_window")
        if not self.window:
            self._die("'main_window' no encontrado en el XML")

        self._load_css()
        self._connect_signals()

        # Señales de ciclo de vida de la ventana
        self.window.connect("map-event",       self._on_window_mapped)
        self.window.connect("key-press-event", self._on_key_press)
        self.window.connect("destroy",         lambda *_: Gtk.main_quit())

        self.window.show_all()

    # ── Carga de UI ───────────────────────────────────────────────────────────

    def _load_ui(self) -> Gtk.Builder:
        if not self._ui_file.exists():
            self._die(f"UI file not found: {self._ui_file}")
        builder = Gtk.Builder()
        try:
            builder.add_from_file(str(self._ui_file))
        except Exception as exc:
            self._die(f"Error cargando XML: {exc}")
        return builder

    # ── Carga de CSS ──────────────────────────────────────────────────────────

    def _load_css(self) -> None:
        if not self._css_file.exists():
            print(f"Warning: CSS no encontrado: {self._css_file}", file=sys.stderr)
            return
        provider = Gtk.CssProvider()
        try:
            provider.load_from_path(str(self._css_file))
            Gtk.StyleContext.add_provider_for_screen(
                Gdk.Screen.get_default(),
                provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
            )
        except Exception as exc:
            print(f"Error cargando CSS: {exc}", file=sys.stderr)

    # ── Conexión de señales ───────────────────────────────────────────────────

    def _connect_signals(self) -> None:
        """Conecta todas las señales y guarda los handler-ids de los toggles."""

        # — Botones normales —
        for btn_id, cmd in LEFT_CLICK_NORMAL.items():
            btn: Gtk.Button | None = self._builder.get_object(btn_id)
            if not btn:
                continue
            btn.connect("clicked",            self._on_button_click,       cmd)
            btn.connect("button-press-event", self._on_right_click_normal, btn_id)

        # — Toggles —
        toggle_handlers = {
            "btn_2": self._on_bluetooth_toggle,
            "btn_6": self._on_nightlight_toggle,
            "btn_8": self._on_airplane_toggle,
        }
        for btn_id, handler in toggle_handlers.items():
            btn: Gtk.ToggleButton | None = self._builder.get_object(btn_id)
            if not btn:
                continue
            # Clase estática: se añade aquí una sola vez y nunca se quita
            static_class, _ = TOGGLE_CSS[btn_id]
            btn.get_style_context().add_class(static_class)
            # Guardamos el handler-id para poder bloquearlo en _sync_toggle
            hid = btn.connect("toggled", handler)
            self._toggle_handler_ids[btn_id] = hid
            btn.connect("button-press-event", self._on_right_click_toggle, btn_id)

        # — Sliders —
        self._brightness_slider: Gtk.Scale | None = self._builder.get_object("slider_brightness")
        self._volume_slider:     Gtk.Scale | None = self._builder.get_object("slider_volume")

        if self._brightness_slider:
            hid = self._brightness_slider.connect("value-changed", self._on_brightness_change)
            self._slider_handler_ids["brightness"] = hid

        if self._volume_slider:
            hid = self._volume_slider.connect("value-changed", self._on_volume_change)
            self._slider_handler_ids["volume"] = hid

    # ── Posicionamiento (Hyprland/Wayland) ────────────────────────────────────

    def _on_window_mapped(self, _window: Gtk.Window, _event: Gdk.EventAny) -> bool:
        """
        Se ejecuta una sola vez tras el primer map-event.
        Inicializa el estado del sistema y posiciona la ventana.

        Nota: window.move() es una API X11 y en Wayland puro es no-op silencioso.
        Todo el posicionamiento real se delega a hyprctl.
        El idle_add garantiza que la ventana tenga tamaño definitivo antes de mover.
        """
        self._initialize_state()
        GLib.idle_add(self._position_hyprctl)
        # Desconectamos la señal para que no vuelva a ejecutarse
        self.window.disconnect_by_func(self._on_window_mapped)
        return False

    def _position_hyprctl(self) -> bool:
        """
        Mueve la ventana a (click_x, click_y + 100) via hyprctl.
        Retorna False para que GLib.idle_add no lo repita.
        """
        try:
            result = subprocess.run(
                ["hyprctl", "clients", "-j"],
                capture_output=True, text=True, timeout=2,
            )
            if result.returncode != 0:
                return False
            clients = json.loads(result.stdout)
            target_x = self.click_x
            target_y = self.click_y + 100
            for client in clients:
                if "Xtra Menu" in client.get("title", ""):
                    subprocess.run(
                        [
                            "hyprctl", "dispatch", "movewindowpixel",
                            f"exact {target_x} {target_y}",
                            f"address:{client['address']}",
                        ],
                        capture_output=True, timeout=2,
                    )
                    break
        except (subprocess.TimeoutExpired, json.JSONDecodeError, OSError) as exc:
            print(f"⚠️  hyprctl error: {exc}", file=sys.stderr)
        return False  # No repetir

    # ── Estado inicial ────────────────────────────────────────────────────────

    def _initialize_state(self) -> None:
        """
        Sincroniza sliders y toggles con el estado real del sistema.
        Las señales se bloquean durante la inicialización para evitar
        efectos secundarios (no se ejecutan comandos del sistema).
        """
        self._init_slider(
            self._brightness_slider,
            "brightness",
            self._read_brightness,
        )
        self._init_slider(
            self._volume_slider,
            "volume",
            self._read_volume,
        )
        self._sync_toggle("btn_2", self._bluetooth_active())
        self._sync_toggle("btn_6", self._nightlight_active())
        self._sync_toggle("btn_8", self._airplane_active())

    def _init_slider(
        self,
        slider: Gtk.Scale | None,
        key: str,
        reader: "callable[[], float | None]", # type: ignore[valid-type]
    ) -> None:
        """Inicializa un slider bloqueando su señal value-changed."""
        if not slider:
            return
        value = reader()
        if value is None:
            return
        hid = self._slider_handler_ids.get(key)
        if hid is not None:
            slider.handler_block(hid)
        slider.set_value(value)
        if hid is not None:
            slider.handler_unblock(hid)

    # ── Lectores del estado del sistema ──────────────────────────────────────

    def _read_brightness(self) -> float | None:
        try:
            cur = int(subprocess.run(
                ["brightnessctl", "get"], capture_output=True, text=True, timeout=2,
            ).stdout.strip())
            mx = int(subprocess.run(
                ["brightnessctl", "max"], capture_output=True, text=True, timeout=2,
            ).stdout.strip())
            return (cur / mx) * 100 if mx else None
        except Exception:
            return None

    def _read_volume(self) -> float | None:
        try:
            return float(subprocess.run(
                ["pamixer", "--get-volume"], capture_output=True, text=True, timeout=2,
            ).stdout.strip())
        except Exception:
            return None

    def _bluetooth_active(self) -> bool:
        try:
            out = subprocess.run(
                ["bluetoothctl", "show"], capture_output=True, text=True, timeout=2,
            ).stdout
            return "Powered: yes" in out
        except Exception:
            return False

    def _nightlight_active(self) -> bool:
        try:
            return subprocess.run(
                ["pgrep", "-x", "hyprsunset"], capture_output=True, timeout=2,
            ).returncode == 0
        except Exception:
            return False

    def _airplane_active(self) -> bool:
        try:
            out = subprocess.run(
                ["nmcli", "radio", "all"], capture_output=True, text=True, timeout=2,
            ).stdout
            # Formato de salida: "WIFI-HW  WIFI     WWAN-HW  WWAN\nenabled  disabled ..."
            # El modo avión deshabilita todo — ningún campo debe ser "enabled"
            lines = out.strip().splitlines()
            if len(lines) < 2:
                return False
            values = lines[1].split()
            return all(v == "disabled" for v in values)
        except Exception:
            return False

    # ── Gestión de apariencia de toggles ─────────────────────────────────────

    def _sync_toggle(self, btn_id: str, is_active: bool) -> None:
        """
        Aplica el estado inicial de un toggle sin disparar el handler 'toggled'.
        Usa el handler-id guardado en _connect_signals para un bloqueo seguro.
        """
        btn: Gtk.ToggleButton | None = self._builder.get_object(btn_id)
        if not btn:
            return
        hid = self._toggle_handler_ids.get(btn_id)
        if hid is not None:
            btn.handler_block(hid)
        btn.set_active(is_active)
        if hid is not None:
            btn.handler_unblock(hid)
        self._apply_toggle_style(btn, btn_id, is_active)

    def _apply_toggle_style(
        self, btn: Gtk.ToggleButton, btn_id: str, is_active: bool
    ) -> None:
        """
        Actualiza icono y clase CSS de estado.
          · Clase estática (.btn-X)         → gestionada en _connect_signals
          · Clase de estado (.btn-X--active) → se añade/quita aquí
        El CSS solo lee estas clases; nunca usa :checked ni IDs compuestos.
        """
        icon_off, icon_on = TOGGLE_ICONS.get(btn_id, ("○", "●"))
        btn.set_label(icon_on if is_active else icon_off)

        _, active_class = TOGGLE_CSS[btn_id]
        ctx = btn.get_style_context()
        if is_active:
            ctx.add_class(active_class)
        else:
            ctx.remove_class(active_class)

    # ── Handlers: toggles ─────────────────────────────────────────────────────

    def _on_bluetooth_toggle(self, btn: Gtk.ToggleButton) -> None:
        is_active = btn.get_active()
        self._apply_toggle_style(btn, "btn_2", is_active)
        self._run_bg(["bluetoothctl", "power", "on" if is_active else "off"])

    def _on_nightlight_toggle(self, btn: Gtk.ToggleButton) -> None:
        is_active = btn.get_active()
        self._apply_toggle_style(btn, "btn_6", is_active)
        if is_active:
            self._run_bg(["hyprsunset", "-t", "3500"], new_session=True)
        else:
            self._run_bg(["pkill", "-x", "hyprsunset"])

    def _on_airplane_toggle(self, btn: Gtk.ToggleButton) -> None:
        is_active = btn.get_active()
        self._apply_toggle_style(btn, "btn_8", is_active)
        self._run_bg(["nmcli", "radio", "all", "off" if is_active else "on"])

    # ── Handlers: botones normales ────────────────────────────────────────────

    def _on_button_click(self, _btn: Gtk.Button, command: list[str]) -> None:
        self._run_bg(command, new_session=True)
        self.window.destroy()

    # ── Handlers: clic derecho ────────────────────────────────────────────────

    def _on_right_click_normal(
        self, _btn: Gtk.Button, event: Gdk.EventButton, btn_id: str
    ) -> bool:
        if event.button != 3:
            return False  # Propagar el evento — no era clic derecho
        cmd = RIGHT_CLICK_NORMAL.get(btn_id)
        if cmd:
            self._run_bg(cmd, new_session=True)
            self.window.destroy()
        return True  # Consumimos el evento solo si era botón 3

    def _on_right_click_toggle(
        self, _btn: Gtk.ToggleButton, event: Gdk.EventButton, btn_id: str
    ) -> bool:
        if event.button != 3:
            return False
        cmd = RIGHT_CLICK_TOGGLE.get(btn_id)
        if cmd:
            self._run_bg(cmd, new_session=True)
            self.window.destroy()
        return True

    # ── Handlers: sliders ────────────────────────────────────────────────────

    def _on_brightness_change(self, scale: Gtk.Scale) -> None:
        self._run_bg(["brightnessctl", "set", f"{int(scale.get_value())}%"])

    def _on_volume_change(self, scale: Gtk.Scale) -> None:
        self._run_bg(["pamixer", "--set-volume", str(int(scale.get_value()))])

    # ── Handler: teclado ──────────────────────────────────────────────────────

    def _on_key_press(self, _window: Gtk.Window, event: Gdk.EventKey) -> bool:
        if event.keyval == Gdk.KEY_Escape:
            self.window.destroy()
        return False

    # ── Utilidades ────────────────────────────────────────────────────────────

    @staticmethod
    def _run_bg(cmd: list[str], *, new_session: bool = False) -> None:
        """Lanza un proceso en segundo plano sin bloquear la UI."""
        try:
            subprocess.Popen(
                cmd,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=new_session,
            )
        except OSError as exc:
            print(f"Error ejecutando {cmd}: {exc}", file=sys.stderr)

    @staticmethod
    def _die(msg: str) -> None:
        print(f"Fatal: {msg}", file=sys.stderr)
        sys.exit(1)


# ──────────────────────────────────────────────────────────────────────────────
# ENTRY POINT
# ──────────────────────────────────────────────────────────────────────────────

def main() -> None:
    if len(sys.argv) != 3:
        print("Uso: xtra_menu.py <x> <y>", file=sys.stderr)
        sys.exit(1)
    try:
        x, y = int(sys.argv[1]), int(sys.argv[2])
    except ValueError:
        print("Error: <x> e <y> deben ser enteros", file=sys.stderr)
        sys.exit(1)

    try:
        XtraMenu(x, y)
        Gtk.main()
    except KeyboardInterrupt:
        sys.exit(0)


if __name__ == "__main__":
    main()
