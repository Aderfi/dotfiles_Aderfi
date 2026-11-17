#!/usr/bin/env python3
import os
import subprocess
import sys
from pathlib import Path

import gi

gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
from gi.repository import Gdk, Gtk, GLib


class XtraMenu:
    """A custom GTK3 menu for Waybar with quick actions and system controls."""
    
    def __init__(self, x=None, y=None, ui_file=None, css_file=None):
        # Store click coordinates from Waybar
        self.click_x = x
        self.click_y = y
        
        # File paths with fallbacks
        self.ui_file = ui_file or os.path.expanduser(
            "~/.config/waybar/custom/xtra_menu.xml"
        )
        self.css_file = css_file or os.path.expanduser(
            "~/.config/waybar/conf/xtra-menu.css"
        )
        
        # Verify files exist
        if not Path(self.ui_file).exists():
            print(f"Error: UI file not found: {self.ui_file}", file=sys.stderr)
            sys.exit(1)
        
        # Load UI
        self.builder = Gtk.Builder()
        try:
            self.builder.add_from_file(self.ui_file)
        except Exception as e:
            print(f"Error loading XML: {e}", file=sys.stderr)
            sys.exit(1)
        
        self.window = self.builder.get_object("main_window")
        if not self.window:
            print("Error: 'main_window' not found in UI file", file=sys.stderr)
            sys.exit(1)
        
        # Configure window as popup
        self.window.set_type_hint(Gdk.WindowTypeHint.POPUP_MENU)
        self.window.set_decorated(False)
        self.window.set_skip_taskbar_hint(True)
        self.window.set_skip_pager_hint(True)
        self.window.set_keep_above(True)
        
        # Load CSS styles
        self.load_css()
        
        # Connect signals
        self.connect_signals()
        
        # Position after window is realized
        self.window.connect("realize", self.on_window_realized)
        self.window.connect("focus-out-event", self.on_focus_out)
        self.window.connect("destroy", self.on_destroy)
        
        # Show window
        self.window.show_all()
    
    def on_window_realized(self, window):
        """Position window after it's realized and we know its size."""
        # Initialize slider values
        self.initialize_sliders()
        
        # Position the window
        self.position_window()
        
        # Grab focus
        self.window.grab_focus()
    
    def load_css(self):
        """Load CSS styles from file."""
        if not Path(self.css_file).exists():
            print(f"Warning: CSS file not found: {self.css_file}", file=sys.stderr)
            return
        
        provider = Gtk.CssProvider()
        try:
            provider.load_from_path(self.css_file)
            screen = Gdk.Screen.get_default()
            Gtk.StyleContext.add_provider_for_screen(
                screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            )
        except Exception as e:
            print(f"Error loading CSS: {e}", file=sys.stderr)
    
    def position_window(self):
        """Position window relative to Waybar button or mouse cursor."""
        display = Gdk.Display.get_default()
        
        # Use provided coordinates or fall back to mouse position
        if self.click_x is not None and self.click_y is not None:
            mouse_x = self.click_x
            mouse_y = self.click_y
        else:
            seat = display.get_default_seat()
            pointer = seat.get_pointer()
            _, mouse_x, mouse_y = pointer.get_position()
        
        # Get window size
        window_width, window_height = self.window.get_size()
        
        # Get monitor geometry
        monitor = display.get_monitor_at_point(mouse_x, mouse_y)
        geometry = monitor.get_geometry()
        
        # Determine Waybar position (top or bottom)
        # If click is in top half of screen, assume waybar is at top
        waybar_at_top = mouse_y < (geometry.height / 2)
        
        # Calculate horizontal position (centered on click)
        final_x = mouse_x - (window_width // 2)
        
        # Calculate vertical position based on Waybar location
        if waybar_at_top:
            # Waybar at top: place menu below the bar
            final_y = mouse_y + 5  # Small offset below waybar
        else:
            # Waybar at bottom: place menu above the bar
            final_y = mouse_y - window_height - 5  # Small offset above waybar
        
        # Ensure we don't go off screen horizontally
        if final_x < geometry.x:
            final_x = geometry.x + 5
        elif final_x + window_width > geometry.x + geometry.width:
            final_x = geometry.x + geometry.width - window_width - 5
        
        # Ensure we don't go off screen vertically
        if final_y < geometry.y:
            final_y = geometry.y + 5
        elif final_y + window_height > geometry.y + geometry.height:
            final_y = geometry.y + geometry.height - window_height - 5
        
        # Move the window
        self.window.move(final_x, final_y)
    
    def connect_signals(self):
        """Connect button clicks and slider changes to handlers."""
        # Button actions mapping
        actions = {
            "btn_1": ["google-chrome-stable"],
            "btn_2": ["thunderbird"],
            "btn_3": ["kitty"],
            "btn_4": ["code"],
            "btn_5": ["amberol"],
            "btn_6": ["mpv"],
            "btn_7": ["gnome-control-center"],
            "btn_8": ["nm-connection-editor"],
            "btn_9": ["wlogout"]
        }
        
        for btn_id, cmd in actions.items():
            btn = self.builder.get_object(btn_id)
            if btn:
                btn.connect("clicked", self.on_button_click, cmd)
            else:
                print(f"Warning: Button '{btn_id}' not found in UI", file=sys.stderr)
        
        # Connect sliders
        self.brightness_slider = self.builder.get_object("slider1")
        self.volume_slider = self.builder.get_object("slider2")
        
        if self.brightness_slider:
            self.brightness_slider.connect("value-changed", self.on_brightness_change)
        
        if self.volume_slider:
            self.volume_slider.connect("value-changed", self.on_volume_change)
    
    def initialize_sliders(self):
        """Set initial slider values from system state."""
        # Get current brightness
        if self.brightness_slider:
            try:
                result = subprocess.run(
                    ["brightnessctl", "get"],
                    capture_output=True,
                    text=True,
                    timeout=2
                )
                if result.returncode == 0:
                    current = int(result.stdout.strip())
                    result_max = subprocess.run(
                        ["brightnessctl", "max"],
                        capture_output=True,
                        text=True,
                        timeout=2
                    )
                    if result_max.returncode == 0:
                        max_val = int(result_max.stdout.strip())
                        percentage = (current / max_val) * 100
                        self.brightness_slider.set_value(percentage)
            except (subprocess.TimeoutExpired, FileNotFoundError, ValueError) as e:
                print(f"Warning: Could not get brightness: {e}", file=sys.stderr)
        
        # Get current volume
        if self.volume_slider:
            try:
                result = subprocess.run(
                    ["pamixer", "--get-volume"],
                    capture_output=True,
                    text=True,
                    timeout=2
                )
                if result.returncode == 0:
                    volume = int(result.stdout.strip())
                    self.volume_slider.set_value(volume)
            except (subprocess.TimeoutExpired, FileNotFoundError, ValueError) as e:
                print(f"Warning: Could not get volume: {e}", file=sys.stderr)
    
    def on_button_click(self, button, command):
        """Handle button clicks by running commands."""
        try:
            subprocess.Popen(
                command,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True
            )
            Gtk.main_quit()
        except FileNotFoundError:
            print(f"Error: Command not found: {command[0]}", file=sys.stderr)
        except Exception as e:
            print(f"Error running command {command}: {e}", file=sys.stderr)
    
    def on_brightness_change(self, scale):
        """Handle brightness slider changes."""
        val = int(scale.get_value())
        try:
            subprocess.Popen(
                ["brightnessctl", "set", f"{val}%"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
        except FileNotFoundError:
            print("Error: brightnessctl not found", file=sys.stderr)
        except Exception as e:
            print(f"Error setting brightness: {e}", file=sys.stderr)
    
    def on_volume_change(self, scale):
        """Handle volume slider changes."""
        val = int(scale.get_value())
        try:
            subprocess.Popen(
                ["pamixer", "--set-volume", str(val)],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
        except FileNotFoundError:
            print("Error: pamixer not found", file=sys.stderr)
        except Exception as e:
            print(f"Error setting volume: {e}", file=sys.stderr)
    
    def on_focus_out(self, window, event):
        """Close menu when focus is lost."""
        GLib.timeout_add(100, Gtk.main_quit)
        return False
    
    def on_destroy(self, *args):
        """Handle window destruction."""
        Gtk.main_quit()


def main():
    """Entry point."""
    # Parse command line arguments for coordinates
    x = None
    y = None
    
    # Waybar puede pasar las coordenadas como argumentos
    if len(sys.argv) >= 3:
        try:
            x = int(sys.argv[1])
            y = int(sys.argv[2])
            print(f"Using coordinates from args: x={x}, y={y}", file=sys.stderr)
        except ValueError:
            print("Warning: Invalid coordinate arguments, using mouse position", file=sys.stderr)
    
    try:
        app = XtraMenu(x=x, y=y)
        Gtk.main()
    except KeyboardInterrupt:
        print("\nInterrupted by user")
        sys.exit(0)
    except Exception as e:
        print(f"Fatal error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()