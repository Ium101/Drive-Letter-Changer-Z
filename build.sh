#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
#  build.sh  —  Drive Letter Changer Z setup
#               Generates icon, creates desktop shortcut and app menu entry
#  Run:    chmod +x build.sh && ./build.sh
#  Output: drive_letter_changer_z.svg   (icon, lives next to the .py)
#          Desktop shortcut             → runs drive_letter_changer_z.py
#          App menu entry               → runs drive_letter_changer_z.py
#                                         (Utilities category)
#  XDG:    ~/.local/share/icons/hicolor/scalable/apps/drivechangerz.svg
#
#  NOTE: Dependencies (PyQt6, pylnk3) are installed automatically
#        the first time drive_letter_changer_z.py is run.
# ─────────────────────────────────────────────────────────────────
set -euo pipefail
cd "$(dirname "$0")"

echo
echo " =========================================="
echo "  Drive Letter Changer Z  --  Linux setup"
echo "  Made by Ium101"
echo " =========================================="
echo

# ── Require Python 3.10+ (for the shortcut Exec= line) ───────────
PYTHON=""
for candidate in python3 python3.13 python3.12 python3.11 python3.10 python; do
    if command -v "$candidate" &>/dev/null; then
        ver=$("$candidate" -c 'import sys; print(sys.version_info >= (3,10))' 2>/dev/null || true)
        if [[ "$ver" == "True" ]]; then
            PYTHON="$candidate"
            break
        fi
    fi
done

if [[ -z "$PYTHON" ]]; then
    echo " ERROR: Python 3.10+ not found in PATH." >&2
    echo "        Install via your package manager:" >&2
    echo "          Debian/Ubuntu:  sudo apt install python3" >&2
    echo "          Fedora/RHEL:    sudo dnf install python3" >&2
    echo "          Arch:           sudo pacman -S python" >&2
    exit 1
fi

PYVER=$("$PYTHON" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo " Found: $PYTHON  (Python $PYVER)"

# Resolve absolute path of this script's directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PY_SCRIPT="$SCRIPT_DIR/drive_letter_changer_z.py"

if [[ ! -f "$PY_SCRIPT" ]]; then
    echo " ERROR: drive_letter_changer_z.py not found in $SCRIPT_DIR" >&2
    exit 1
fi

# ── Install / upgrade dependencies ───────────────────────────────
echo " Checking dependencies..."
if ! "$PYTHON" -m pip install --quiet --upgrade pylnk3 PyQt6 2>/dev/null; then
    "$PYTHON" -m pip install --quiet --upgrade --break-system-packages pylnk3 PyQt6
fi
echo " OK   Dependencies ready."

# ── Directories ──────────────────────────────────────────────────
APP_DIR="$HOME/.local/share/applications"
# SVG icons belong in hicolor/scalable/apps — correct XDG path.
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
mkdir -p "$APP_DIR" "$ICON_DIR"

# Resolve Desktop dir safely; fall back to ~/Desktop
DESKTOP_DIR="$HOME/Desktop"
if command -v xdg-user-dir &>/dev/null; then
    _d="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
    # Accept the xdg result only if it's non-empty and actually a directory
    # (or at least a non-root absolute path we can create).
    if [[ -n "$_d" && "$_d" != "/" ]]; then
        DESKTOP_DIR="$_d"
    fi
fi
mkdir -p "$DESKTOP_DIR" 2>/dev/null || {
    echo " WARNING: Could not create Desktop dir ($DESKTOP_DIR), using ~/Desktop" >&2
    DESKTOP_DIR="$HOME/Desktop"
    mkdir -p "$DESKTOP_DIR" 2>/dev/null || true
}

# ── SVG Icon ─────────────────────────────────────────────────────
# Teal gradient + shimmer + 'Z:' label.
# Written both next to the .py (drive_letter_changer_z.svg, used by build.bat
# on Windows to generate the .ico) and into the XDG icon theme.
echo " Installing icon..."
SVG_CONTENT='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="256" height="256">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%"   stop-color="#2C9D8F"/>
      <stop offset="100%" stop-color="#16635B"/>
    </linearGradient>
    <linearGradient id="shimmer" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%"   stop-color="#FFFFFF" stop-opacity="0.18"/>
      <stop offset="100%" stop-color="#FFFFFF" stop-opacity="0.00"/>
    </linearGradient>
    <clipPath id="rr">
      <rect x="1" y="1" width="62" height="62" rx="14" ry="14"/>
    </clipPath>
  </defs>
  <rect x="1" y="1" width="62" height="62" rx="14" ry="14" fill="url(#bg)"/>
  <rect x="1" y="1" width="62" height="32" fill="url(#shimmer)" clip-path="url(#rr)"/>
  <text x="33" y="45" font-family="'"'"'Courier New'"'"',Courier,monospace"
        font-size="31" font-weight="bold"
        fill="#000000" fill-opacity="0.25" text-anchor="middle">Z:</text>
  <text x="32" y="44" font-family="'"'"'Courier New'"'"',Courier,monospace"
        font-size="31" font-weight="bold"
        fill="#FFFFFF" text-anchor="middle">Z:</text>
</svg>'

# Write next to the .py — this is the canonical source file, used by
# build.bat on Windows to render the matching .ico.
LOCAL_SVG="$SCRIPT_DIR/drive_letter_changer_z.svg"
printf '%s\n' "$SVG_CONTENT" > "$LOCAL_SVG"
echo " OK   Icon (local):  $LOCAL_SVG"

# Install into XDG icon theme so the .desktop Icon= name resolves.
ICON_SVG="$ICON_DIR/drivechangerz.svg"
mkdir -p "$ICON_DIR" 2>/dev/null || true
cp "$LOCAL_SVG" "$ICON_SVG"
echo " OK   Icon (XDG):    $ICON_SVG"

# Refresh GTK icon cache so 'drivechangerz' resolves immediately.
# Suppress all output and errors — this is a best-effort hint to the DE.
for _cache_cmd in gtk-update-icon-cache gtk4-update-icon-cache; do
    if command -v "$_cache_cmd" &>/dev/null; then
        "$_cache_cmd" -f -t "$HOME/.local/share/icons/hicolor" &>/dev/null || true
        break
    fi
done

# ── Helper: write a .desktop entry ───────────────────────────────
# Uses printf to avoid heredoc variable-expansion pitfalls with paths
# that contain $, backticks, or other shell-special characters.
# The Exec value quotes $PY_SCRIPT so paths with spaces work correctly.
write_desktop() {
    local dest="$1"
    # Build the Exec line: quote the script path so spaces are handled.
    # .desktop files accept double-quoted arguments (freedesktop spec).
    printf '%s\n' \
        '[Desktop Entry]' \
        'Name=Drive Letter Changer Z' \
        'Comment=Retarget drive letters in .lnk shortcuts and Linux symlinks' \
        "Exec=$PYTHON \"$PY_SCRIPT\"" \
        'Icon=drivechangerz' \
        'Terminal=false' \
        'Type=Application' \
        'Categories=Utility;' \
        > "$dest" || { echo " ERROR: Could not write $dest" >&2; return 1; }
    chmod 755 "$dest" || true
}

# ── System menu entry (Utilities category) ────────────────────────
echo " Adding to system menu (Utilities)..."
mkdir -p "$APP_DIR" 2>/dev/null || true
write_desktop "$APP_DIR/DriveLetterChangerZ.desktop" || \
    echo " WARNING: Could not write system menu entry." >&2
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$APP_DIR" &>/dev/null || true
fi

# ── Desktop shortcut ─────────────────────────────────────────────
echo " Creating Desktop shortcut..."
DESK_FILE="$DESKTOP_DIR/Drive Letter Changer Z.desktop"
write_desktop "$DESK_FILE" || \
    echo " WARNING: Could not write Desktop shortcut." >&2

# Mark as trusted so the DE runs it on double-click without a prompt.
# Both gio and setfattr are best-effort; suppress all errors.
if command -v gio &>/dev/null; then
    gio set "$DESK_FILE" metadata::trusted true 2>/dev/null || true
fi
# KDE Plasma trust flag (needs 'attr' package)
if command -v setfattr &>/dev/null; then
    setfattr -n user.IsExecutable -v 1 "$DESK_FILE" 2>/dev/null || true
fi
# GNOME / Nautilus: also try xdg-open trick to register the file
# (some distros need this for the shortcut to be clickable)
if command -v dbus-send &>/dev/null; then
    dbus-send --session --dest=org.freedesktop.FileManager1 \
        --type=method_call /org/freedesktop/FileManager1 \
        org.freedesktop.FileManager1.ShowItems \
        "array:string:file://$DESK_FILE" string:"" &>/dev/null || true
fi

# ── KDE menu cache refresh ────────────────────────────────────────
echo " Refreshing menu cache..."
if command -v kbuildsycoca6 &>/dev/null; then
    kbuildsycoca6 &>/dev/null || true
elif command -v kbuildsycoca5 &>/dev/null; then
    kbuildsycoca5 &>/dev/null || true
fi

echo
echo " =========================================="
echo "  Setup complete!"
echo " =========================================="
echo
echo "  Script:    $PY_SCRIPT"
echo "  Icon:      $LOCAL_SVG"
echo "  XDG icon:  $ICON_SVG"
echo "  Menu:      $APP_DIR/DriveLetterChangerZ.desktop"
echo "  Desktop:   $DESK_FILE"
echo "  Settings:  $SCRIPT_DIR/drive_changer_z_config_linux.ini  (created on first run)"
echo
echo " To run:"
echo "    Double-click the Desktop shortcut"
echo "    Or: $PYTHON '$PY_SCRIPT'"
echo "    Or: $PYTHON '$PY_SCRIPT' --no-gui [DIR]"
echo "    Or: $PYTHON '$PY_SCRIPT' --help"
echo
