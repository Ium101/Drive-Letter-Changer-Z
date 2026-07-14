#!/usr/bin/env python3
"""
Drive Letter Changer Z — Retarget Windows drive letters inside .lnk shortcuts
and Linux symbolic links from a selected folder.
GUI: PyQt6 (native Dolphin file picker via kdialog / XDG portal on KDE).
CLI: pass --no-gui
Made by Ium101
"""

import os, sys, re, json, argparse, subprocess, configparser, codecs, struct
from pathlib import Path
from dataclasses import dataclass, field
from typing import Optional

# ── Windows: resolve 8.3 short names to real long names ───────────
def _win_longpath(p: Path) -> Path:
    """
    On Windows, Qt's file dialog (and NTFS itself) can return paths with
    8.3 short-name components such as PROGRA~1 or USERSF~1.  These work
    fine as paths but look wrong in the UI and in .lnk tooltips.
    GetLongPathNameW resolves every component to its true long name.
    Safe no-op on Linux (returns p unchanged).
    """
    if os.name != "nt":
        return p
    import ctypes
    buf = ctypes.create_unicode_buffer(32768)
    n = ctypes.windll.kernel32.GetLongPathNameW(str(p), buf, len(buf))
    if n and n < len(buf):
        return Path(buf.value)
    return p

# ── Codec shim: 'ansi' is a valid alias on Windows but unknown on Linux ────
def _register_ansi_codec():
    try:
        codecs.lookup("ansi")
    except LookupError:
        codecs.register(lambda name: codecs.lookup("cp1252") if name == "ansi" else None)
_register_ansi_codec()

# ── Dependency bootstrap ───────────────────────────────────────
def _pip(*pkgs, extra=[]):
    subprocess.check_call(
        [sys.executable, "-m", "pip", "install", "--quiet", "--upgrade"] + list(pkgs) + extra,
        stderr=subprocess.DEVNULL)

def _ensure(pkg, import_name=None):
    name = import_name or pkg
    try:
        __import__(name); return True
    except ImportError:
        pass
    for extra in [[], ["--break-system-packages"]]:
        try:
            _pip(pkg, extra=extra); __import__(name); return True
        except Exception:
            pass
    return False

_HAVE_PYLNK3 = _ensure("pylnk3")
if _HAVE_PYLNK3:
    import pylnk3

# ── i18n ──────────────────────────────────────────────────────
_S = {
"en": dict(
    title="Drive Letter Changer Z", credit="Made by Ium101",
    lang_toggle="PT-BR",
    theme_dark="☀  Light",
    theme_light="🌙  Dark",
    folder_label="Folder to scan:", browse="Browse Folder…", browse_file="Select File…", scan="Scan",
    select_all="Select All", select_none="Select None",
    mapping_title="Drive letter remapping",
    mapping_hint="Map each detected drive letter to its new drive letter:",
    mapping_hint_linux="Map each detected Windows drive to its new Linux mount path (or a single letter):",
    old_letter="Old letter", new_letter_ph="New letter (e.g. D)",
    old_mount_label="Old mount", new_mount_ph="New path (e.g. /mnt/d)",
    browse_mount="Browse…",
    err_bad_path="Enter a valid mount path (starting with /) or a single drive letter (A–Z).",
    err_same_path="Old and new mount paths are the same — nothing to do.",
    recursive="Scan sub-folders",
    detect_lnk_toggle="Also detect Windows .lnk shortcuts",
    dry="Dry run (preview only)", apply="Apply",
    tab_main="Remap", tab_log="Log",
    col_file="File", col_path="Path", col_kind="Type",
    col_old="Old drive", col_new="New drive", col_status="Status",
    kind_lnk=".lnk shortcut", kind_sym="symlink",
    kind_lnk_sym=".lnk → symlink",
    ready="Ready.", scanning="Scanning…",
    done="Done — changed: {c}  skipped: {s}  errors: {e}",
    done_dry="[DRY RUN] Would change: {c}  skipped: {s}  errors: {e}",
    no_folder="Please select a folder first.",
    no_lnk="No .lnk files or symlinks found.",
    no_pylnk3="pylnk3 could not be installed.\nRun: pip install pylnk3",
    log_scan="Scanning {r}…", log_found="Found {n} item(s).",
    log_ok="✓  {f}  {old}:  →  {new}:",
    log_ok_sym="✓  {f}  →  symlink: {target}",
    log_skip="–  {f} ({r})", log_err="✗  {f}: {r}",
    log_dry="[DRY RUN] Would change: {f}  {old}:  →  {new}:",
    log_dry_sym="[DRY RUN] Would create symlink: {lnk}  →  {target}",
    err_bad_letter="Enter a single drive letter (A–Z).",
    err_same="Old and new letters are the same — nothing to do.",
    reason_deselected="deselected",
),
"pt": dict(
    title="Drive Letter Changer Z", credit="Feito por Ium101",
    lang_toggle="EN-US",
    theme_dark="☀  Claro",
    theme_light="🌙  Escuro",
    folder_label="Pasta para escanear:", browse="Escolher Pasta…", browse_file="Escolher Arquivo…", scan="Escanear",
    select_all="Selecionar Tudo", select_none="Selecionar Nenhum",
    mapping_title="Remapeamento de letras de drive",
    mapping_hint="Mapeie cada letra de drive detectada para sua nova letra:",
    mapping_hint_linux="Mapeie cada drive Windows detectado para seu novo caminho de montagem Linux (ou uma letra):",
    old_letter="Letra antiga", new_letter_ph="Nova letra (ex: D)",
    old_mount_label="Montagem antiga", new_mount_ph="Novo caminho (ex: /mnt/d)",
    browse_mount="Escolher…",
    err_bad_path="Insira um caminho de montagem válido (iniciando com /) ou uma letra de drive (A–Z).",
    err_same_path="Caminhos de montagem antigo e novo são iguais — nada a fazer.",
    recursive="Escanear subpastas",
    detect_lnk_toggle="Detectar também atalhos .lnk do Windows",
    dry="Simulação (apenas visualizar)", apply="Aplicar",
    tab_main="Remap", tab_log="Log",
    col_file="Arquivo", col_path="Caminho", col_kind="Tipo",
    col_old="Drive antigo", col_new="Drive novo", col_status="Status",
    kind_lnk="atalho .lnk", kind_sym="symlink",
    kind_lnk_sym=".lnk → symlink",
    ready="Pronto.", scanning="Escaneando…",
    done="Concluído — alterados: {c}  pulados: {s}  erros: {e}",
    done_dry="[SIMULAÇÃO] Alteraria: {c}  pulados: {s}  erros: {e}",
    no_folder="Por favor selecione uma pasta primeiro.",
    no_lnk="Nenhum arquivo .lnk ou symlink encontrado.",
    no_pylnk3="pylnk3 não pôde ser instalado.\nExecute: pip install pylnk3",
    log_scan="Escaneando {r}…", log_found="{n} item(s) encontrado(s).",
    log_ok="✓  {f}  {old}:  →  {new}:",
    log_ok_sym="✓  {f}  →  symlink: {target}",
    log_skip="–  {f} ({r})", log_err="✗  {f}: {r}",
    log_dry="[SIMULAÇÃO] Alteraria: {f}  {old}:  →  {new}:",
    log_dry_sym="[SIMULAÇÃO] Criaria symlink: {lnk}  →  {target}",
    err_bad_letter="Insira uma única letra de drive (A–Z).",
    err_same="Letra antiga e nova são iguais — nada a fazer.",
    reason_deselected="desmarcado",
),
}
_LANG = "en"
def T(k, **kw):
    s = _S[_LANG].get(k, _S["en"].get(k, k))
    return s.format(**kw) if kw else s

def T_detect_other():
    """Label for the optional cross-platform detection toggle.
    Only meaningful on Linux (detect Windows .lnk files).
    On Windows the toggle is hidden entirely."""
    return T("detect_lnk_toggle")

# ── Persistent config ──────────────────────────────────────────
_IS_WINDOWS    = (os.name == "nt")
_CONFIG_DIR    = Path(__file__).resolve().parent
_CONFIG_SUFFIX = "windows" if _IS_WINDOWS else "linux"
_CONFIG_FILE   = _CONFIG_DIR / f"drive_changer_z_config_{_CONFIG_SUFFIX}.ini"
_INI_MAIN      = "main"
_INI_LETTERS   = "letter_map"    # old_letter -> new_letter, persisted uppercase
_INI_OLD_PATHS = "old_path_map"  # old_letter -> old mount path (Linux only), persisted

def load_config() -> dict:
    if _CONFIG_FILE.exists():
        try:
            cp = configparser.ConfigParser()
            cp.read(_CONFIG_FILE, encoding="utf-8")
            result: dict = {}
            if cp.has_option(_INI_MAIN, "last_folder"):
                result["last_folder"] = cp.get(_INI_MAIN, "last_folder")
            if cp.has_option(_INI_MAIN, "lang"):
                result["lang"] = cp.get(_INI_MAIN, "lang")
            if cp.has_option(_INI_MAIN, "recursive"):
                result["recursive"] = cp.getboolean(_INI_MAIN, "recursive")
            if cp.has_option(_INI_MAIN, "dark_mode"):
                result["dark_mode"] = cp.getboolean(_INI_MAIN, "dark_mode")
            if cp.has_option(_INI_MAIN, "detect_other"):
                result["detect_other"] = cp.getboolean(_INI_MAIN, "detect_other")
            if cp.has_section(_INI_LETTERS):
                # configparser lowercases keys; restore keys to uppercase.
                # Values: uppercase only if they are single letters (drive letters).
                # Full paths (starting with "/") must preserve their case.
                def _restore_val(v: str) -> str:
                    v = v.strip()
                    if v and not v.startswith("/") and len(v) == 1:
                        # Windows keys: uppercase; Linux single-letter paths: lowercase
                        return v.upper() if _IS_WINDOWS else v.lower()
                    return v
                result["letter_map"] = {k.upper(): _restore_val(v)
                                        for k, v in cp.items(_INI_LETTERS)}
            if cp.has_section(_INI_OLD_PATHS):
                # Keys are drive letters (uppercased); values are Linux mount paths.
                result["old_path_map"] = {k.upper(): v.strip()
                                          for k, v in cp.items(_INI_OLD_PATHS)
                                          if v.strip()}
            return result
        except Exception:
            pass
    return {}

def save_config(data: dict):
    try:
        cp = configparser.ConfigParser()
        cp[_INI_MAIN] = {}
        for key in ("last_folder", "lang"):
            if key in data:
                cp[_INI_MAIN][key] = str(data[key])
        for key in ("recursive", "dark_mode", "detect_other"):
            if key in data:
                cp[_INI_MAIN][key] = "true" if data[key] else "false"
        lmap = data.get("letter_map", {})
        if lmap:
            def _save_val(v: str) -> str:
                v = v.strip()
                if v and not v.startswith("/") and len(v) == 1:
                    # Windows: uppercase drive letters; Linux: lowercase path components
                    return v.upper() if _IS_WINDOWS else v.lower()
                return v
            cp[_INI_LETTERS] = {k.lower(): _save_val(v) for k, v in lmap.items()}
        omap = data.get("old_path_map", {})
        if omap and not _IS_WINDOWS:
            cp[_INI_OLD_PATHS] = {k.lower(): v for k, v in omap.items() if v.strip()}
        tmp = _CONFIG_FILE.with_suffix(".tmp")
        with open(tmp, "w", encoding="utf-8") as f:
            cp.write(f)
        tmp.replace(_CONFIG_FILE)
    except Exception:
        pass

# ── Core data ──────────────────────────────────────────────────
@dataclass
class Entry:
    path:               Path
    kind:               str   = ""          # "lnk" or "symlink"
    old_letter:         str   = ""          # detected drive letter (uppercase)
    old_target:         str   = ""          # full original target string
    old_mount_path:     str   = ""          # Linux symlinks: full mount path, e.g. /mnt/c
    new_letter:         str   = ""          # filled by plan() — display letter or short label
    new_target:         str   = ""          # filled by plan()
    new_mount_path:     str   = ""          # Linux symlinks: full new mount path, e.g. /mnt/d
    # Linux-only: when a .lnk file is processed on Linux, we create a sibling
    # symlink instead of modifying the .lnk.  These carry the planned output.
    lnk_symlink_path:   Optional[Path] = None   # e.g. /some/dir/shortcut.lnk → /some/dir/shortcut
    lnk_symlink_target: str   = ""              # Linux path the new symlink will point to
    # Linux-only: for a symlink whose name matches the stem of a sibling .lnk,
    # this holds the associated .lnk Entry.  When set, old_letter is overridden
    # with the letter read from the .lnk (not the symlink's current target).
    lnk_source:         Optional["Entry"] = None
    error:              Optional[str] = None
    status:             str   = "pending"
    included:           bool  = True        # False = user deselected this row; skipped on Apply

# ── LNK rewriting ─────────────────────────────────────────────
_LONGPATH_PREFIX_RE = re.compile(r'^\\\\[?.]\\')
_ENV_TOKEN_RE       = re.compile(r'%([^%]+)%')

def _drive_from_path(raw: str) -> Optional[str]:
    """Return uppercase drive letter from a Windows path, or None."""
    raw = raw.strip()
    raw = _LONGPATH_PREFIX_RE.sub("", raw)
    m = re.match(r'^([A-Za-z])[:\\/]', raw)
    return m.group(1).upper() if m else None

def _swap_letter_in_path(path_str: str, old: str, new: str) -> str:
    """Replace the drive letter in a Windows path string."""
    old_u, new_u = old.upper(), new.upper()
    m = re.match(r'^(\\\\[?.]\\)?([A-Za-z])([:].*)$', path_str, re.DOTALL)
    if m and m.group(2).upper() == old_u:
        return (m.group(1) or "") + new_u + m.group(3)
    # plain X\... form (no colon)
    m2 = re.match(r'^([A-Za-z])([\\/].*)$', path_str, re.DOTALL)
    if m2 and m2.group(1).upper() == old_u:
        return new_u + m2.group(2)
    return path_str

# ── LNK path-field enumeration ──────────────────────────────────
#
# pylnk3's `.path` property is READ-ONLY (assigning to it raises
# "property 'path' of 'Lnk' object has no setter") and its own internal
# resolution order can surface an *unresolved* shell "known folder"
# placeholder such as '::{GUID}\Users\...' even when the LinkInfo
# structure already holds the real, working local path (e.g.
# 'C:\Users'). Windows Explorer shows the LinkInfo path in that
# situation, so we check the real underlying fields ourselves instead
# of trusting `.path`, in priority order that matches what Explorer
# actually resolves.
def _lnk_path_spots(lnk):
    """
    Enumerate every string field of a parsed .lnk that can legitimately
    hold a drive-lettered Windows path.  Returns a list of
    (label, get, set) tuples; `set` is None for read-only spots.
    """
    spots = []

    li = getattr(lnk, "link_info", None)
    if li is not None:
        if getattr(li, "local_base_path", None):
            def _set_li(v, li=li):
                li.local_base_path = v
                try:
                    li.make_path()
                except Exception:
                    pass
            spots.append(("link_info.local_base_path",
                          lambda li=li: li.local_base_path, _set_li))
        # common_path (base_name on remote LinkInfo) also carries a drive letter
        # on some shortcut types, and is the field pylnk3's .path property falls
        # back to on Linux when local_base_path is absent.
        if getattr(li, "base_name", None):
            def _set_bn(v, li=li):
                li.base_name = v
                try:
                    li.make_path()
                except Exception:
                    pass
            spots.append(("link_info.base_name",
                          lambda li=li: li.base_name, _set_bn))

    if getattr(lnk, "relative_path", None):
        spots.append(("relative_path",
                      lambda lnk=lnk: lnk.relative_path,
                      lambda v, lnk=lnk: setattr(lnk, "relative_path", v)))

    if getattr(lnk, "work_dir", None):
        spots.append(("work_dir",
                      lambda lnk=lnk: lnk.work_dir,
                      lambda v, lnk=lnk: setattr(lnk, "work_dir", v)))

    if getattr(lnk, "arguments", None):
        spots.append(("arguments",
                      lambda lnk=lnk: lnk.arguments,
                      lambda v, lnk=lnk: setattr(lnk, "arguments", v)))

    # A drive letter embedded directly in the shell item ID list
    # (present for shortcuts built from a plain "X:\..." target).
    idl = getattr(lnk, "shell_item_id_list", None)
    if idl is not None:
        for item in getattr(idl, "items", []):
            if isinstance(item, pylnk3.DriveEntry) and getattr(item, "drive", None):
                def _set_drv(v, item=item):
                    letter = _drive_from_path(v) or (v[:1] if v else "")
                    if letter:
                        item.drive = (letter.upper() + ":").encode()
                spots.append(("shell_item_id_list drive entry",
                              lambda item=item: item.drive.decode(errors="ignore"),
                              _set_drv))

    # Last resort, READ-ONLY: pylnk3's own best-effort resolved path.
    # Useful only to surface *something* in error messages when no
    # writable field carries a drive letter at all (e.g. a pure
    # known-folder reference with no LinkInfo present).
    try:
        resolved = lnk.path
    except Exception:
        resolved = None
    if resolved:
        spots.append(("path (read-only)", lambda resolved=resolved: resolved, None))

    return spots


def _lnk_find_letter(lnk):
    """
    Return (letter, display_value, label) for the first spot carrying
    a recognisable drive letter, or (None, best_display, "") if none
    of the fields contain one.
    """
    fallback_display = ""
    for label, get, _set in _lnk_path_spots(lnk):
        try:
            val = get()
        except Exception:
            continue
        if not val:
            continue
        if not fallback_display:
            fallback_display = val
        letter = _drive_from_path(val)
        if letter:
            return letter, val, label
    return None, fallback_display, ""


def _rewrite_lnk(src: Path, old: str, new: str, dry: bool) -> str:
    """
    Rewrite the drive letter in every writable path field of a .lnk
    file that currently carries `old`. Returns the new primary target
    string (for display). Raises on any hard error.
    """
    lnk = pylnk3.parse(str(src))

    changed = False
    changed_labels = set()
    new_primary = ""

    for label, get, set_ in _lnk_path_spots(lnk):
        if set_ is None:
            continue
        try:
            val = get()
        except Exception:
            continue
        if not val or _drive_from_path(val) != old.upper():
            continue
        new_val = _swap_letter_in_path(val, old, new)
        set_(new_val)
        changed = True
        changed_labels.add(label)
        if not new_primary or label == "link_info.local_base_path":
            new_primary = new_val

    if not changed:
        raise ValueError(f"drive {old}: not found in shortcut fields")

    # When there's no LinkInfo (a plain shell-item-list-only shortcut),
    # new_primary above is just the bare "E:" from the DriveEntry — build
    # a nicer full-path preview from the (now-updated) ID list instead.
    if "link_info.local_base_path" not in changed_labels:
        try:
            idl_display = lnk.shell_item_id_list.get_path()
            prefix = "%MY_COMPUTER%\\"
            if idl_display.startswith(prefix):
                idl_display = idl_display[len(prefix):]
            if not idl_display.startswith("::") and _drive_from_path(idl_display):
                new_primary = idl_display
        except Exception:
            pass

    if not dry:
        lnk.save(str(src))

    return new_primary

# ── Symlink rewriting ──────────────────────────────────────────
def _parse_symlink_target(sym: Path) -> Optional[tuple]:
    """
    Try to interpret the symlink target as a drive-letter mount path.

    Recognised patterns (X = single letter, case-insensitive):
      • /mnt/x/rest          → prefix="/mnt/", letter=X, rest="rest"
      • /media/x/rest        → prefix="/media/", letter=X, rest="rest"
      • /run/media/.../x/rest→ prefix="/run/media/.../", letter=X, rest="rest"
      • /x/rest              → prefix="", letter=X, rest="rest"
      • x/rest  (relative)   → prefix="", letter=X, rest="rest"
      • X:\\rest  (Windows)  → treated as drive X with Windows path
      • X:/rest  (Windows)   → treated as drive X with Windows path

    Returns (letter_upper, prefix, rest, original_target) or None if the
    target doesn't contain a recognisable single-letter drive component.
    """
    try:
        tgt = os.readlink(sym)
    except OSError:
        return None
    tgt = tgt.strip()

    # Windows-style absolute path: X:\rest or X:/rest
    m = re.match(r'^([A-Za-z])[:\\/](.*)$', tgt)
    if m:
        letter, rest = m.group(1), m.group(2)
        return (letter.upper(), "", rest, tgt)

    # Unix path: find the rightmost single-letter path component and treat
    # everything before it as the mount prefix, everything after as the rest.
    # This handles /mnt/x/..., /media/x/..., /run/media/user/x/..., /x/...
    # while rejecting paths like /home/user/Music where no component is a
    # single letter that could be a drive letter.
    parts_all = [p for p in tgt.lstrip("/").split("/") if p]
    if parts_all:
        for i, seg in enumerate(parts_all):
            if len(seg) == 1 and seg.isalpha():
                rest_parts = parts_all[i + 1:]
                if not rest_parts:
                    continue   # single-letter with nothing after — not a drive path
                prefix_parts = parts_all[:i]
                prefix_str = ("/" + "/".join(prefix_parts) + "/") if prefix_parts else "/"
                rest_str   = "/".join(rest_parts)
                return (seg.upper(), prefix_str, rest_str, tgt)

    return None


def _parse_symlink_target_general(sym: Path):
    """
    Like _parse_symlink_target but also returns the raw target for
    symlinks whose target does NOT follow a drive-letter mount pattern.
    Returns (letter, prefix, rest, original) for drive-style targets,
    or (None, None, None, original) for plain/unrecognised targets.
    """
    try:
        tgt = os.readlink(sym)
    except OSError:
        return (None, None, None, "")
    result = _parse_symlink_target(sym)
    if result:
        return result
    return (None, None, None, tgt.strip())


def _rewrite_symlink(sym: Path, old: str, new: str,
                     old_target: str, dry: bool,
                     old_mount_path: str = "") -> str:
    """
    Repoint the symlink at a new target.

    Strategy:
    1. If old_mount_path is set and the target starts with it → plain prefix swap.
       This handles symlinks created by lnk2symlink with named mount points like
       /mnt/Disco_Local/Music — there's no single drive letter to find.
    2. If _parse_symlink_target finds a single-letter drive component → swap it.
    3. Letter text-substitution fallback (old-style drive-letter symlinks).
    """
    new_is_path = (not _IS_WINDOWS) and new.startswith("/")
    tgt = old_target
    if not tgt:
        try: tgt = os.readlink(sym)
        except OSError: tgt = ""

    # ── Strategy 1: prefix swap ───────────────────────────────────────────
    if new_is_path and old_mount_path:
        old_prefix = old_mount_path.rstrip("/")
        new_prefix = new.rstrip("/")
        if tgt == old_prefix or tgt.startswith(old_prefix + "/"):
            rest = tgt[len(old_prefix):]  # "" or "/something/..."
            new_tgt = new_prefix + rest
            if not dry:
                tmp = sym.parent / (sym.name + ".__tmp__")
                try: tmp.unlink()
                except FileNotFoundError: pass
                tmp.symlink_to(new_tgt)
                tmp.replace(sym)
            return new_tgt

    # ── Strategy 2: single-letter drive component ─────────────────────────
    parsed = _parse_symlink_target(sym)
    if parsed is not None:
        letter, prefix, rest, orig = parsed
        if letter != old.upper():
            raise ValueError(f"target letter {letter} ≠ expected {old}")
        new_tgt = new.rstrip("/") + "/" + rest if new_is_path else f"{prefix}{new.lower()}/{rest}"
    else:
        # ── Strategy 3: letter text substitution ──────────────────────────
        if new_is_path:
            raise ValueError(
                f"Cannot remap {tgt!r}: old mount path {old_mount_path!r} "
                f"not found as a prefix. Check the left field.")
        new_tgt = tgt
        substituted = False
        for pat, repl in [
            (re.compile(r'(?<![A-Za-z])' + re.escape(old.upper()) + r'(?=[/\\])'), new.upper()),
            (re.compile(r'(?<![A-Za-z])' + re.escape(old.lower()) + r'(?=[/\\])'), new.lower()),
        ]:
            result = pat.sub(repl, new_tgt, count=1)
            if result != new_tgt:
                new_tgt = result; substituted = True; break
        if not substituted:
            raise ValueError(f"drive letter {old}: not found in symlink target {tgt!r}")

    if not dry:
        tmp = sym.parent / (sym.name + ".__tmp__")
        try: tmp.unlink()
        except FileNotFoundError: pass
        tmp.symlink_to(new_tgt)
        tmp.replace(sym)
    return new_tgt

# ── Scanner ────────────────────────────────────────────────────
def _classify_entry(p: Path, detect_other: bool, force: bool = False,
                    _is_sym: Optional[bool] = None) -> Optional["Entry"]:
    """
    Inspect a single filesystem path and return the Entry describing it,
    or None if this run should skip it entirely.

    force=True bypasses the native-kind-only gating (used when the user
    explicitly hand-picks one file via the "Select File…" button — if they
    picked it on purpose we report on it regardless of platform/detect_other).

    _is_sym: pre-computed is_symlink() result from os.scandir's DirEntry.
    Passing it avoids a second lstat() call and, critically, ensures correct
    detection of directory symlinks/junctions on Windows where Path.is_symlink()
    can silently return False without follow_symlinks=False being threaded
    through every call.  When None (single-file path, force=True), we fall
    back to p.is_symlink() as before.
    """
    is_sym = _is_sym if _is_sym is not None else p.is_symlink()
    if is_sym:
        # On Windows, only scan symlinks when detect_other is on (symlinks are
        # uncommon on Windows and the user must opt in).
        # On Linux, always scan symlinks — they are the native output format.
        if _IS_WINDOWS and not detect_other and not force:
            return None
        e = Entry(path=p, kind="symlink")
        parsed = _parse_symlink_target(p)
        if parsed:
            # Recognised drive-letter mount pattern — full support.
            e.old_letter = parsed[0]
            e.old_target = parsed[3]
            if not _IS_WINDOWS:
                # Build the Linux mount path: prefix + letter (e.g. /mnt/ + c → /mnt/c)
                prefix = parsed[1] or ""
                e.old_mount_path = (prefix + parsed[0].lower()).rstrip("/") or ("/" + parsed[0].lower())
        else:
            # Generic symlink: target has no recognisable single-letter drive
            # component (e.g. /mnt/Disco_Local/Music — created by lnk2symlink
            # with a named mount point rather than a single-letter one).
            # Populate old_mount_path from the target's parent directory so
            # the user sees it in the left field and can set the new path.
            try:
                raw_tgt = os.readlink(p)
            except OSError as exc:
                raw_tgt = ""
                e.error = str(exc)
            e.old_target = raw_tgt
            if raw_tgt and not e.error:
                # Derive old_mount_path as everything up to (not including)
                # the last path component.  e.g. /mnt/Disco_Local/Music →
                # old_mount_path = /mnt/Disco_Local, rest = Music.
                # Use the parent of the target as the mount path so the user
                # can replace just the mount part.
                tgt_path = Path(raw_tgt)
                parent = str(tgt_path.parent)
                if parent and parent != raw_tgt:
                    e.old_mount_path = parent
                # old_letter stays empty — we key the mapping row on
                # old_mount_path for generic symlinks (set in _rebuild_letter_rows).
        return e
    elif p.suffix.lower() == ".lnk":
        # On Windows, .lnk is the native format — always scan.
        # On Linux, .lnk files are the primary input for this tool (the whole
        # point is to read them and create sibling symlinks) — always scan,
        # never gate behind detect_other.
        if not _HAVE_PYLNK3:
            return Entry(path=p, kind="lnk", error="pylnk3 missing")
        e = Entry(path=p, kind="lnk")
        try:
            lnk = pylnk3.parse(str(p))
            letter, display, _label = _lnk_find_letter(lnk)
            e.old_target = display
            if letter:
                e.old_letter = letter
            elif display.startswith("::"):
                e.error = "target is a Windows special/known folder (no drive letter to remap)"
            elif display:
                e.error = f"no drive letter found: {display!r}"
            else:
                e.error = "no path information found in shortcut"
        except Exception as ex:
            e.error = str(ex)
        return e
    elif force:
        # User explicitly picked this exact file via the file dialog and it's
        # neither a .lnk nor a symlink — report that instead of silently
        # ignoring their choice.
        return Entry(path=p, kind="?", error="not a .lnk shortcut or a symlink")
    return None


def _scandir_entries(root: Path, recursive: bool) -> list:
    """
    Collect all filesystem entries under root using os.scandir().
    Unlike Path.rglob(), os.scandir() populates DirEntry.is_symlink()
    correctly on Windows (including directory junctions / symlinks that
    NTFS exposes), which is essential for the "detect Linux symlinks on
    Windows" feature.  Also applies _win_longpath() so 8.3 short-name
    components (e.g. PROGRA~1) are resolved to their real long names
    before any Path object is created or stored.
    """
    collected = []
    try:
        queue = [root]
        while queue:
            current = queue.pop(0)   # FIFO — preserve the sorted order we built
            dirs_here = []
            try:
                with os.scandir(current) as it:
                    for entry in sorted(it, key=lambda e: e.name.lower()):
                        p = _win_longpath(Path(entry.path))
                        # Capture symlink status from DirEntry BEFORE
                        # constructing a Path — Path.is_symlink() on
                        # Windows can silently return False for directory
                        # symlinks/junctions unless follow_symlinks=False
                        # is explicitly threaded through, but DirEntry
                        # always uses lstat and is reliable.
                        is_sym = entry.is_symlink()
                        collected.append((p, is_sym))
                        if recursive and entry.is_dir(follow_symlinks=False):
                            dirs_here.append(p)
            except PermissionError:
                continue
            # Extend queue with subdirs in sorted order so the BFS stays
            # fully alphabetical at every depth level.
            queue.extend(dirs_here)
    except PermissionError:
        pass
    return collected


def _link_symlinks_to_lnk_siblings(entries: list):
    """
    Linux-only post-scan pass.

    When a directory contains both a .lnk file (e.g. "!Media Y.lnk") and a
    symlink whose name is the stem of that .lnk (e.g. "!Media Y"), the two are
    almost certainly related: the symlink was created (by this tool or manually)
    to act as the Linux equivalent of the Windows shortcut.

    In that situation the symlink's current target may point at the WRONG
    mount (e.g. /mnt/x/Media) while the .lnk correctly records the intended
    drive (Y).  Parsing the symlink's own target would surface the wrong letter
    ("X:"), confusing the user.

    Fix: set the symlink entry's old_letter to match the sibling .lnk entry,
    and annotate it with a reference to the .lnk entry (lnk_source).  The old
    target string is kept for display purposes, but remapping will now use the
    letter from the .lnk, which is the authoritative source of truth.

    We also clear any stale error set by classify_entry when the symlink target
    didn't contain a recognisable drive letter — the .lnk gives us the letter
    now, so it's no longer an error.
    """
    if _IS_WINDOWS:
        return

    # Build a quick lookup: (parent_dir, stem) → lnk Entry
    lnk_by_stem: dict = {}
    for e in entries:
        if e.kind == "lnk" and e.old_letter and not e.error:
            key = (e.path.parent, e.path.stem)
            lnk_by_stem[key] = e

    for e in entries:
        if e.kind != "symlink":
            continue
        key = (e.path.parent, e.path.name)   # symlink name == .lnk stem
        lnk_e = lnk_by_stem.get(key)
        if lnk_e is None:
            continue
        # Found a paired .lnk — override this symlink's letter with the one
        # from the .lnk so the user sees the correct drive in both rows.
        e.lnk_source  = lnk_e
        e.old_letter  = lnk_e.old_letter
        # Clear a "no drive letter" / "not recognised" error if any — the .lnk
        # gives us the letter authoritatively.
        if e.error and (
            "no drive letter" in e.error or
            "not found" in e.error or
            "not recognised" in e.error
        ):
            e.error  = None
            e.status = "pending"
        # Keep old_mount_path if it was already set (recognised mount pattern).
        # If it wasn't set (generic symlink / wrong mount) leave it empty so
        # plan() will compute the correct new mount from the letter_map.


def scan_folder(root: Path, recursive: bool = True, detect_other: bool = False) -> list:
    """
    detect_other: when False (default), only the shortcut type native
    to the current OS is scanned — .lnk files on Windows, symlinks on
    Linux/other. Set True to also detect the "other" platform's kind
    (e.g. Linux symlinks found on a Windows machine, or Windows .lnk
    files found on a Linux machine).
    """
    entries = []
    for p, is_sym in _scandir_entries(root, recursive):
        try:
            e = _classify_entry(p, detect_other, _is_sym=is_sym)
            if e is not None:
                entries.append(e)
        except Exception as ex:
            entries.append(Entry(path=p, kind="?", error=str(ex)))

    # On Linux: link pre-existing symlinks to their sibling .lnk files so
    # that the correct drive letter (from the .lnk) is used for both display
    # and remapping, even if the symlink currently points at the wrong mount.
    _link_symlinks_to_lnk_siblings(entries)

    return entries


def scan_single_file(path: Path, detect_other: bool = False) -> list:
    """
    Classify exactly one explicitly-picked file (from the "Select File…"
    button) and return a 0- or 1-item entries list, matching scan_folder's
    return shape so both can feed the same downstream code.
    """
    try:
        e = _classify_entry(path, detect_other, force=True)
        return [e] if e is not None else []
    except Exception as ex:
        return [Entry(path=path, kind="?", error=str(ex))]

def _lnk_windows_rest(old_target: str) -> str:
    """
    Extract the path portion after the drive letter from a Windows target
    string stored in a .lnk file, normalising backslashes to forward slashes.
    e.g.  "C:\\Users\\Alice\\file.txt"  →  "Users/Alice/file.txt"
          "C:/Users/Alice"              →  "Users/Alice"
    Returns "" if the string doesn't start with a drive letter.
    """
    m = re.match(r'^(?:\\\\[?.]\\)?[A-Za-z][:\\/]+(.*)$', old_target, re.DOTALL)
    if not m:
        return ""
    return m.group(1).replace("\\", "/").strip("/")


def _lnk_symlink_name(lnk_path: Path) -> Path:
    """
    Return the sibling path where the new symlink should be created.
    We strip the .lnk extension so  /foo/bar/shortcut.lnk → /foo/bar/shortcut.
    If the stem is empty for some reason, append '_link'.
    """
    stem = lnk_path.stem or (lnk_path.name + "_link")
    return lnk_path.parent / stem


def plan(entries: list, letter_map: dict):
    """Fill new_letter / new_target / new_mount_path / status for each entry.

    letter_map values may be:
      • A single letter (A–Z)  — used on all platforms and always for .lnk files
        on Windows.
      • A full mount path starting with "/"  — Linux only, for both symlinks and
        .lnk files.  e.g. "/mnt/d" or "/media/usb".

    Linux .lnk behaviour (new):
      On Linux we never modify the .lnk binary.  Instead we compute a Linux path
      from the Windows target inside the .lnk and create a sibling symlink
      (same directory, no .lnk extension) pointing to that Linux path.
      The symlink is created/overwritten atomically, so running Apply twice is
      idempotent.
    """
    for e in entries:
        if e.error:
            e.status = "error"; continue
        if not e.old_letter:
            # On Linux, symlinks whose targets don't contain a recognisable
            # drive-letter component have no old_letter.  That is not an error
            # in the file itself — it's a symlink we can't remap without more
            # information.  Show it as skipped (yellow) not error (red).
            if not _IS_WINDOWS:
                e.error = "no drive letter found in target"
                e.status = "skipped"
            else:
                e.error = "no drive letter"
                e.status = "error"
            continue

        # ── Generic Linux symlink: keyed by old_mount_path, not old_letter ─
        # Symlinks created by lnk2symlink point to e.g. /mnt/Disco_Local/Music.
        # They have no drive letter in the path, so old_letter is empty.
        # We surface them in the mapping rows keyed by old_mount_path instead.
        if not _IS_WINDOWS and e.kind == "symlink" and not e.old_letter and e.old_mount_path:
            raw_new = letter_map.get(e.old_mount_path, "").strip()
            if not raw_new:
                e.error = f"mount {e.old_mount_path}: not mapped"
                e.status = "skipped"; continue
            new_prefix = raw_new.rstrip("/")
            old_prefix = e.old_mount_path.rstrip("/")
            rest = e.old_target[len(old_prefix):] if e.old_target.startswith(old_prefix) else ""
            e.new_target     = new_prefix + rest
            e.new_mount_path = raw_new
            e.new_letter     = Path(raw_new).name
            continue

        raw_new = letter_map.get(e.old_letter.upper(), "").strip()
        if not raw_new:
            e.error = f"drive {e.old_letter}: not mapped"
            e.status = "skipped"; continue

        # Detect Linux path mode: value is a full mount path like "/mnt/d"
        new_is_path = (not _IS_WINDOWS) and raw_new.startswith("/")

        # ── Linux .lnk → create sibling symlink ───────────────────────────
        # On Linux, .lnk files are read-only artefacts from Windows.  Rather
        # than rewriting their binary content (which would break them on the
        # Windows side), we derive the equivalent Linux path and create a
        # native symlink next to the .lnk file.  The symlink name is the .lnk
        # stem (e.g. "shortcut.lnk" → "shortcut").
        if not _IS_WINDOWS and e.kind == "lnk":
            rest = _lnk_windows_rest(e.old_target)
            if new_is_path:
                new_mount = raw_new.rstrip("/")
                linux_target = (f"{new_mount}/{rest}" if rest else new_mount)
            else:
                # Single-letter: build /mnt/<letter>/<rest> as a sane default
                letter_low = raw_new.lower()
                linux_target = (f"/mnt/{letter_low}/{rest}" if rest else f"/mnt/{letter_low}")

            sym_path = _lnk_symlink_name(e.path)
            e.lnk_symlink_path   = sym_path
            e.lnk_symlink_target = linux_target
            e.new_mount_path     = raw_new if new_is_path else ""
            last = Path(raw_new).name if new_is_path else raw_new.lower()
            e.new_letter = last.lower() if re.match(r'^[A-Za-z]$', last) else raw_new
            e.new_target = linux_target
            # No same-path check needed: the .lnk path ≠ the symlink path.
            continue   # skip the generic path below

        # ── Linux symlink paired with a sibling .lnk ──────────────────────
        # When a pre-existing symlink is correlated with a sibling .lnk file
        # (lnk_source is set by the scan-linking pass), we use the Windows
        # path from the .lnk to compute the correct Linux target — not the
        # symlink's current (possibly wrong) target.  This is the same logic
        # as the .lnk→create-sibling-symlink path above, applied to an
        # already-existing symlink that needs to be corrected.
        if not _IS_WINDOWS and e.kind == "symlink" and e.lnk_source is not None:
            rest = _lnk_windows_rest(e.lnk_source.old_target)
            if new_is_path:
                new_mount = raw_new.rstrip("/")
                linux_target = (f"{new_mount}/{rest}" if rest else new_mount)
            else:
                letter_low = raw_new.lower()
                linux_target = (f"/mnt/{letter_low}/{rest}" if rest else f"/mnt/{letter_low}")
            e.new_mount_path = raw_new if new_is_path else ""
            last = Path(raw_new).name if new_is_path else raw_new.lower()
            e.new_letter = last.lower() if re.match(r'^[A-Za-z]$', last) else raw_new
            e.new_target = linux_target
            # No same-path check for the "correcting a wrong symlink" case —
            # the old target is already wrong so we always want to write.
            continue   # skip generic symlink handling below

        if new_is_path:
            new_mount = raw_new.rstrip("/")
            e.new_mount_path = new_mount
            # Derive a display letter from the last path component when it's a
            # single letter (e.g. /mnt/d → d), otherwise display the path itself.
            last = Path(new_mount).name
            e.new_letter = last.lower() if re.match(r'^[A-Za-z]$', last) else new_mount

            # Same-destination check
            old_norm = e.old_mount_path.rstrip("/") if e.old_mount_path else ""
            if new_mount == old_norm:
                e.error = "old and new mount paths are the same"
                e.status = "skipped"; continue

            # Compute preview of new target (symlinks on Linux, .lnk on Windows)
            if e.kind == "lnk":
                # Windows .lnk: letter-based rewriting; derive letter
                lnk_letter = last.upper() if re.match(r'^[A-Za-z]$', last) else e.old_letter
                e.new_target = _swap_letter_in_path(e.old_target, e.old_letter, lnk_letter)
            else:
                parsed = _parse_symlink_target(e.path)
                if parsed:
                    _, prefix, rest, _ = parsed
                    e.new_target = f"{new_mount}/{rest}"
                else:
                    # Generic symlink: show a best-effort preview
                    e.new_target = e.old_target.replace(
                        f"/{e.old_letter.lower()}/",
                        f"/{last.lower() if re.match(r'^[A-Za-z]$', last) else last}/", 1)
        else:
            # Classic single-letter mode
            new_letter = raw_new.upper()
            e.new_mount_path = ""
            if new_letter == e.old_letter.upper():
                e.error = "old and new letters are the same"
                e.status = "skipped"; continue
            e.new_letter = new_letter
            # Compute preview of new target
            if e.kind == "lnk":
                e.new_target = _swap_letter_in_path(e.old_target, e.old_letter, new_letter)
            else:
                parsed = _parse_symlink_target(e.path)
                if parsed:
                    _, prefix, rest, _ = parsed
                    e.new_target = f"{prefix}{new_letter.lower()}/{rest}"
                else:
                    e.new_target = e.old_target.replace(
                        f"/{e.old_letter.lower()}/", f"/{new_letter.lower()}/", 1)

def _create_lnk_symlink(sym_path: Path, target: str, dry: bool):
    """
    Create (or overwrite) a Linux symlink at `sym_path` pointing to `target`.

    Uses an atomic tmp→rename so a pre-existing symlink with the same name
    (from a previous run) is replaced without a window where the path
    disappears.  Raises OSError on any failure.
    """
    if dry:
        return
    tmp = sym_path.parent / (sym_path.name + ".__tmp__")
    # Remove any stale tmp left over from a crashed previous run.
    try:
        tmp.unlink()
    except FileNotFoundError:
        pass
    tmp.symlink_to(target)
    tmp.replace(sym_path)   # atomic on Linux (POSIX rename)


def do_apply(e: Entry, dry: bool):
    """Apply the remapping for one entry."""
    try:
        if not _IS_WINDOWS and e.kind == "lnk" and e.lnk_symlink_path is not None:
            # Linux .lnk mode: create a sibling symlink — never touch the .lnk.
            _create_lnk_symlink(e.lnk_symlink_path, e.lnk_symlink_target, dry)
            e.new_target = e.lnk_symlink_target
        elif not _IS_WINDOWS and e.kind == "symlink" and e.lnk_source is not None:
            # Pre-existing symlink correlated with a sibling .lnk: overwrite it
            # with the correct Linux target derived from the .lnk's Windows path.
            # plan() already computed new_target; pass it via _create_lnk_symlink
            # which handles the atomic tmp→rename for us.
            _create_lnk_symlink(e.path, e.new_target, dry)
        elif e.kind == "lnk":
            # Windows (or explicit letter-only mode): rewrite the .lnk in place.
            if e.new_mount_path:
                last = Path(e.new_mount_path).name
                lnk_letter = last.upper() if re.match(r'^[A-Za-z]$', last) else e.old_letter
            else:
                lnk_letter = e.new_letter
            e.new_target = _rewrite_lnk(e.path, e.old_letter, lnk_letter, dry)
        else:
            # Symlinks: use full mount path on Linux when one was set.
            sym_new = e.new_mount_path if (not _IS_WINDOWS and e.new_mount_path) else e.new_letter
            e.new_target = _rewrite_symlink(
                e.path, e.old_letter or "_", sym_new, e.old_target, dry,
                old_mount_path=e.old_mount_path)
        e.status = "created"
    except Exception as ex:
        e.status = "error"; e.error = str(ex)

# ── Mount listing (for reference only — not used in remapping logic) ──
def list_mounts():
    try:
        out = subprocess.check_output(
            ["lsblk", "-o", "MOUNTPOINT,LABEL,SIZE", "--noheadings", "--json"],
            text=True, stderr=subprocess.DEVNULL)
        data   = json.loads(out)
        results = []
        def walk(devs):
            for d in devs:
                mp = d.get("mountpoint", "")
                if mp and mp != "[SWAP]":
                    results.append((mp, d.get("label", "") or "", d.get("size", "") or ""))
                for c in d.get("children", []):
                    walk([c])
        walk(data.get("blockdevices", []))
        return results
    except Exception:
        return []

# ── Folder picker — dispatches per-OS ─────────────────────────
#
#  Windows: use Qt's native Windows folder-browser dialog directly.
#           No subprocess, no os.getuid() — none of the Linux-only
#           code is touched, so there is nothing to crash.
#
#  Linux:   Dolphin (kdialog) → KDE QFileDialog → zenity → Qt fallback.
#           All Linux-specific helpers are kept strictly inside the
#           Linux branch so they can never run on Windows.

def _pick_folder(parent_widget, title: str, start_dir: str) -> Optional[str]:
    """Open a native folder-browser dialog; return chosen path or None."""
    # Resolve to absolute before passing on — .as_uri() (used by Linux pickers)
    # raises ValueError on relative paths such as "." or an unanchored name.
    try:
        start_dir = str(Path(start_dir).resolve())
    except Exception:
        pass
    if not start_dir or not Path(start_dir).exists():
        start_dir = str(Path.home())
    if _IS_WINDOWS:
        return _pick_folder_windows(parent_widget, title, start_dir)
    else:
        return _pick_folder_linux(parent_widget, title, start_dir)


def _pick_folder_windows(parent_widget, title: str, start_dir: str) -> Optional[str]:
    """Windows: Qt's native IFileOpenDialog — no subprocess, no getuid."""
    from PyQt6.QtWidgets import QFileDialog
    chosen = QFileDialog.getExistingDirectory(
        parent_widget, title, start_dir,
        QFileDialog.Option.ShowDirsOnly)
    return chosen if chosen else None


def _pick_file(parent_widget, title: str, start_dir: str) -> Optional[str]:
    """
    Open a native single-file picker (for the "Select File…" button) and
    return the chosen path, or None if cancelled. Qt's getOpenFileName
    dialog is reliably native on both Windows and Linux, so — unlike the
    folder picker above — no per-OS dispatch/subprocess fallback is needed.
    """
    from PyQt6.QtWidgets import QFileDialog
    if _IS_WINDOWS:
        name_filter = "Shortcuts (*.lnk);;All files (*)"
    else:
        name_filter = "All files (*)"
    chosen, _selected_filter = QFileDialog.getOpenFileName(
        parent_widget, title, start_dir, name_filter)
    return chosen if chosen else None


# ── Linux-only helpers (never imported / called on Windows) ───

def _ensure_dbus_env():
    if os.environ.get("DBUS_SESSION_BUS_ADDRESS"):
        return
    uid = os.getuid()                    # Linux-only — never reached on Windows
    socket_path = f"/run/user/{uid}/bus"
    if Path(socket_path).exists():
        os.environ["DBUS_SESSION_BUS_ADDRESS"] = f"unix:path={socket_path}"
        return
    try:
        for pid_dir in Path("/proc").iterdir():
            if not pid_dir.name.isdigit():
                continue
            try:
                name = (pid_dir / "comm").read_text().strip()
            except OSError:
                continue
            if name not in ("plasmashell", "gnome-shell", "kwin_wayland",
                            "kwin_x11", "mutter", "xfwm4"):
                continue
            try:
                raw = (pid_dir / "environ").read_bytes()
                for item in raw.split(b"\x00"):
                    if item.startswith(b"DBUS_SESSION_BUS_ADDRESS="):
                        os.environ["DBUS_SESSION_BUS_ADDRESS"] = \
                            item.split(b"=", 1)[1].decode()
                        return
            except OSError:
                continue
    except OSError:
        pass

def _is_kde() -> bool:
    desk = os.environ.get("XDG_CURRENT_DESKTOP", "").lower()
    return "kde" in desk or "plasma" in desk

def _pick_folder_linux(parent_widget, title: str, start_dir: str) -> Optional[str]:
    """
    Linux folder picker — modern tree-based dialogs first, plain fallbacks only
    if no modern picker could be opened at all.

    Priority
    ────────
    1. kdialog  (KDE native tree picker — Dolphin-style, works on KDE/Plasma)
    2. XDG Desktop Portal via D-Bus  (modern tree picker on GNOME ≥ 3.33, KDE ≥ 5.x,
                                      any portal-capable compositor)
    3. Qt native dialog with portal env hint  (tells Qt to route through the portal;
                                               renders the same tree UI on most DEs)
    4. zenity   ← fallback only if both modern pickers above failed to open at all
    5. Qt plain QFileDialog  ← last resort

    Steps 4 and 5 are skipped entirely as long as any step 1-3 dialog was at least
    *launched* (even if the user cancelled it), so the modern UI is always preferred.
    """
    from PyQt6.QtWidgets import QFileDialog, QApplication
    _ensure_dbus_env()
    # Resolve to absolute — relative paths raise ValueError in .as_uri()
    start_dir = str(Path(start_dir).resolve())
    start_uri = Path(start_dir).as_uri()

    # ── shared URI → path helper ─────────────────────────────────
    def _decode_uri(raw: str) -> Optional[str]:
        raw = raw.strip()
        if not raw:
            return None
        if raw.startswith("file://"):
            from urllib.parse import unquote
            raw = unquote(raw[7:])
        p = Path(raw)
        if p.is_dir():   return str(p)
        if p.exists():   return str(p.parent)
        return None

    # ── 1. kdialog (KDE native, Dolphin-style tree view) ─────────
    # FileNotFoundError  → kdialog not installed, try next tier.
    # returncode == 0    → user picked a folder, decode and return.
    # returncode != 0    → user cancelled (or dialog error); stop here
    #                       so we don't pop a second dialog on top.
    for kdialog_bin in ("kdialog", "kdialog6"):
        try:
            result = subprocess.run(
                [kdialog_bin, "--title", title, "--getexistingdirectory", start_uri],
                capture_output=True, text=True)   # no timeout — user is browsing
            # Dialog opened successfully (regardless of cancel/ok).
            if result.returncode == 0:
                chosen = _decode_uri(result.stdout)
                if chosen:
                    return chosen
            # returncode 1 = user cancelled; any other code = internal error.
            # Either way the dialog *was shown* — do not fall through to
            # non-tree pickers.
            return None
        except FileNotFoundError:
            continue   # kdialog not present, try next option

    # ── 2. XDG Desktop Portal via D-Bus ──────────────────────────
    # This produces the native file-chooser tree dialog on GNOME (Nautilus
    # picker), KDE Plasma, and any other compositor that implements
    # org.freedesktop.portal.FileChooser.  We call it directly over D-Bus
    # so it works even when the Qt platform theme isn't set to "gnome".
    #
    # Protocol summary:
    #   • Call OpenFile on org.freedesktop.portal.FileChooser
    #   • Pass handle_token so we can subscribe to the Response signal
    #   • Wait (blocking) on the signal; result[0]==0 means OK
    #   • The "uris" key in result[1] holds the chosen folder URI(s)
    try:
        import dbus                                    # python3-dbus / dbus-python
        bus          = dbus.SessionBus()
        portal_obj   = bus.get_object(
            "org.freedesktop.portal.Desktop",
            "/org/freedesktop/portal/desktop")
        file_chooser = dbus.Interface(
            portal_obj, "org.freedesktop.portal.FileChooser")

        import random, string, time
        token    = "dlcz_" + "".join(random.choices(string.ascii_lowercase, k=8))
        # The response signal path is /org/freedesktop/portal/desktop/request/<sender>/<token>
        # where <sender> is the unique bus name with dots replaced by underscores.
        sender        = bus.get_unique_name().lstrip(":").replace(".", "_")
        request_path  = f"/org/freedesktop/portal/desktop/request/{sender}/{token}"

        chosen_uri    = [None]   # shared mutable cell for the callback
        dialog_opened = [False]

        import dbus.mainloop.glib
        from gi.repository import GLib
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        loop = GLib.MainLoop()

        def _on_response(response, results):
            dialog_opened[0] = True
            if response == 0:
                uris = results.get("uris", [])
                if uris:
                    chosen_uri[0] = str(uris[0])
            loop.quit()

        bus.add_signal_receiver(
            _on_response,
            signal_name="Response",
            dbus_interface="org.freedesktop.portal.Request",
            path=request_path)

        # parent_window_id: empty string = no parent (dialog becomes top-level)
        options = dbus.Dictionary({
            "handle_token":     dbus.String(token),
            "title":            dbus.String(title),
            "directory":        dbus.Boolean(True),
            "current_folder":   dbus.ByteArray(start_dir.encode() + b"\x00"),
        }, signature="sv")
        file_chooser.OpenFile("", title, options)

        # Run the GLib main loop; quit() is called inside _on_response.
        # We also set a generous poll so the loop never hangs forever if
        # the signal somehow never arrives (e.g. portal crashed).
        _deadline = [time.monotonic() + 3600]   # 1-hour hard ceiling
        def _watchdog():
            if time.monotonic() >= _deadline[0]:
                loop.quit()
                return False   # remove source
            return True         # keep polling
        GLib.timeout_add_seconds(30, _watchdog)
        loop.run()

        if dialog_opened[0] or chosen_uri[0] is not None:
            # Dialog was shown (user may have cancelled → chosen_uri stays None)
            return _decode_uri(chosen_uri[0]) if chosen_uri[0] else None

        # Fall through: portal present but signal never fired (unusual)

    except Exception:
        pass   # dbus/gi not installed, portal unavailable, etc. — try next tier

    # ── 3. Qt native dialog with portal env hint ──────────────────
    # Set GTK_USE_PORTAL=1 and QT_QPA_PLATFORMTHEME to encourage Qt to
    # route through the XDG portal, which renders the same modern tree UI.
    # This is a best-effort hint; if Qt ignores it the dialog still opens
    # (as the Qt built-in non-tree picker) and we count that as "opened".
    _app         = QApplication.instance()
    _saved_qss   = _app.styleSheet() if _app else ""
    _orig_theme  = os.environ.get("QT_QPA_PLATFORMTHEME")
    _orig_portal = os.environ.get("GTK_USE_PORTAL")
    try:
        os.environ["GTK_USE_PORTAL"]      = "1"
        os.environ["QT_QPA_PLATFORMTHEME"] = "xdgdesktopportal"
        if _app:
            _app.setStyleSheet("")
        dlg = QFileDialog(parent_widget)
        dlg.setWindowTitle(title)
        dlg.setFileMode(QFileDialog.FileMode.Directory)
        dlg.setOption(QFileDialog.Option.ShowDirsOnly, True)
        dlg.setOption(QFileDialog.Option.DontUseNativeDialog, False)
        dlg.setDirectory(start_dir)
        # exec() blocks until the user closes the dialog — the dialog was
        # opened, so regardless of accept/reject we do NOT fall further.
        accepted = dlg.exec()
        if accepted:
            dirs = dlg.selectedFiles()
            if dirs:
                chosen = dirs[0]
                return str(Path(chosen).parent) if not Path(chosen).is_dir() else chosen
        return None
    except Exception:
        pass
    finally:
        if _app and _saved_qss:
            _app.setStyleSheet(_saved_qss)
        if _orig_theme is None:   os.environ.pop("QT_QPA_PLATFORMTHEME", None)
        else:                     os.environ["QT_QPA_PLATFORMTHEME"] = _orig_theme
        if _orig_portal is None:  os.environ.pop("GTK_USE_PORTAL", None)
        else:                     os.environ["GTK_USE_PORTAL"] = _orig_portal

    # ══ Fallbacks — only reached if ALL modern pickers above failed to open ══

    # ── 4. zenity (GTK dialog, not tree-based but widely available) ──
    try:
        result = subprocess.run(
            ["zenity", "--title", title, "--file-selection", "--directory",
             f"--filename={start_dir}/"],
            capture_output=True, text=True)   # no timeout — user is browsing
        if result.returncode == 0:
            chosen = result.stdout.strip()
            if chosen and Path(chosen).is_dir():
                return chosen
        if result.returncode in (0, 1):
            return None   # dialog opened; user cancelled
    except FileNotFoundError:
        pass

    # ── 5. Qt plain QFileDialog (absolute last resort) ────────────
    chosen = QFileDialog.getExistingDirectory(
        parent_widget, title, start_dir, QFileDialog.Option.ShowDirsOnly)
    return chosen if chosen else None

# ── GUI ────────────────────────────────────────────────────────
def run_gui():
    global _LANG
    from PyQt6.QtWidgets import (
        QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
        QLabel, QLineEdit, QPushButton, QCheckBox, QTabWidget,
        QTreeWidget, QTreeWidgetItem, QScrollArea,
        QTextEdit, QStatusBar, QFrame, QSizePolicy, QFileDialog,
        QMessageBox, QGroupBox
    )
    from PyQt6.QtCore import Qt, QThread, pyqtSignal
    from PyQt6.QtGui import QFont, QColor, QPalette, QTextCharFormat, QTextCursor, QIcon
    import base64

    app = QApplication(sys.argv)
    app.setApplicationName("Drive Letter Changer Z")

    # ── Global exception guard ──────────────────────────────────
    # PyQt6 aborts the *entire* process when a Python exception escapes
    # a slot (e.g. a button's clicked handler) instead of just printing
    # it like plain Python normally would. In a --noconsole/--windowed
    # build there's no console to show the traceback either, so the
    # app just vanishes with zero warning the instant something throws
    # -- this is exactly what happened when clicking "Browse Folder…"
    # on certain folders/drives. Installing our own excepthook stops
    # Qt from tearing the whole app down and shows the error instead.
    def _global_excepthook(exc_type, exc_value, exc_tb):
        import traceback
        details = "".join(traceback.format_exception(exc_type, exc_value, exc_tb))
        try:
            sys.stderr.write(details)
        except Exception:
            pass
        try:
            with open(_CONFIG_DIR / "drive_changer_z_error.log", "a", encoding="utf-8") as fh:
                fh.write(details + "\n")
        except Exception:
            pass
        try:
            QMessageBox.critical(None, "Drive Letter Changer Z — Error",
                                  f"An unexpected error occurred:\n\n{exc_value}\n\n"
                                  f"The app will stay open. Details were saved to "
                                  f"drive_changer_z_error.log")
        except Exception:
            pass

    sys.excepthook = _global_excepthook

    _cfg = load_config()
    if _cfg.get("lang") in ("en", "pt"):
        _LANG = _cfg["lang"]

    # ── Dark mode detection ───────────────────────────────────
    def _detect_dark_mode() -> bool:
        try:
            from PyQt6.QtCore import Qt as _Qt
            scheme = app.styleHints().colorScheme()
            if scheme == _Qt.ColorScheme.Dark:  return True
            if scheme == _Qt.ColorScheme.Light: return False
        except Exception:
            pass
        for cmd in (
            ["kreadconfig5", "--group", "General", "--key", "ColorScheme"],
            ["kreadconfig6", "--group", "General", "--key", "ColorScheme"],
        ):
            try:
                r = subprocess.run(cmd, capture_output=True, text=True, timeout=2)
                s = (r.stdout or "").strip().lower()
                if s: return "dark" in s
            except Exception:
                pass
        try:
            r = subprocess.run(
                ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"],
                capture_output=True, text=True, timeout=2)
            if (r.stdout or "").strip().lower():
                return "dark" in r.stdout.lower()
        except Exception:
            pass
        try:
            win_color = app.palette().color(QPalette.ColorRole.Window)
            return win_color.lightness() < 128
        except Exception:
            pass
        return True

    _cfg_startup = load_config()
    _dark_mode_state = [
        _cfg_startup["dark_mode"] if "dark_mode" in _cfg_startup else _detect_dark_mode()
    ]

    # ── Bundled SVG icon — teal gradient + shimmer + Z: label ────
    # Identical design to the SVG written by build.sh / build.bat.
    _icon_svg_b64 = (
        "PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2NCA2"
        "NCIgd2lkdGg9IjY0IiBoZWlnaHQ9IjY0Ij4KICA8ZGVmcz4KICAgIDxsaW5lYXJHcmFkaWVudCBp"
        "ZD0iYmciIHgxPSIwJSIgeTE9IjAlIiB4Mj0iMCUiIHkyPSIxMDAlIj4KICAgICAgPHN0b3Agb2Zm"
        "c2V0PSIwJSIgICBzdG9wLWNvbG9yPSIjMkM5RDhGIi8+CiAgICAgIDxzdG9wIG9mZnNldD0iMTAw"
        "JSIgc3RvcC1jb2xvcj0iIzE2NjM1QiIvPgogICAgPC9saW5lYXJHcmFkaWVudD4KICAgIDxsaW5l"
        "YXJHcmFkaWVudCBpZD0ic2hpbW1lciIgeDE9IjAlIiB5MT0iMCUiIHgyPSIwJSIgeTI9IjEwMCUi"
        "PgogICAgICA8c3RvcCBvZmZzZXQ9IjAlIiAgIHN0b3AtY29sb3I9IiNGRkZGRkYiIHN0b3Atb3Bh"
        "Y2l0eT0iMC4xOCIvPgogICAgICA8c3RvcCBvZmZzZXQ9IjEwMCUiIHN0b3AtY29sb3I9IiNGRkZG"
        "RkYiIHN0b3Atb3BhY2l0eT0iMC4wMCIvPgogICAgPC9saW5lYXJHcmFkaWVudD4KICAgIDxjbGlw"
        "UGF0aCBpZD0icnIiPgogICAgICA8cmVjdCB4PSIxIiB5PSIxIiB3aWR0aD0iNjIiIGhlaWdodD0i"
        "NjIiIHJ4PSIxNCIgcnk9IjE0Ii8+CiAgICA8L2NsaXBQYXRoPgogIDwvZGVmcz4KICA8cmVjdCB4"
        "PSIxIiB5PSIxIiB3aWR0aD0iNjIiIGhlaWdodD0iNjIiIHJ4PSIxNCIgcnk9IjE0IiBmaWxsPSJ1"
        "cmwoI2JnKSIvPgogIDxyZWN0IHg9IjEiIHk9IjEiIHdpZHRoPSI2MiIgaGVpZ2h0PSIzMiIgZmls"
        "bD0idXJsKCNzaGltbWVyKSIgY2xpcC1wYXRoPSJ1cmwoI3JyKSIvPgogIDx0ZXh0IHg9IjMzIiB5"
        "PSI0NSIgZm9udC1mYW1pbHk9IidDb3VyaWVyIE5ldycsQ291cmllcixtb25vc3BhY2UiCiAgICAgICAg"
        "Zm9udC1zaXplPSIzMSIgZm9udC13ZWlnaHQ9ImJvbGQiCiAgICAgICAgZmlsbD0iIzAwMDAwMCIgZmls"
        "bC1vcGFjaXR5PSIwLjI1IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIj5aOjwvdGV4dD4KICA8dGV4dCB4"
        "PSIzMiIgeT0iNDQiIGZvbnQtZmFtaWx5PSInQ291cmllciBOZXcnLENvdXJpZXIsbW9ub3NwYWNlIgog"
        "ICAgICAgIGZvbnQtc2l6ZT0iMzEiIGZvbnQtd2VpZ2h0PSJib2xkIgogICAgICAgIGZpbGw9IiNGRkZG"
        "RkYiIHRleHQtYW5jaG9yPSJtaWRkbGUiPlo6PC90ZXh0Pgo8L3N2Zz4="
    )
    try:
        from PyQt6.QtCore import QByteArray
        from PyQt6.QtSvg import QSvgRenderer
        from PyQt6.QtGui import QPixmap, QPainter
        svg_bytes = base64.b64decode(_icon_svg_b64)
        renderer  = QSvgRenderer(QByteArray(svg_bytes))
        pixmap    = QPixmap(64, 64)
        pixmap.fill(Qt.GlobalColor.transparent)
        painter   = QPainter(pixmap)
        renderer.render(painter)
        painter.end()
        app.setWindowIcon(QIcon(pixmap))
    except Exception:
        pass

    # ── Theme ─────────────────────────────────────────────────
    def _theme_colors(dark: bool):
        if dark:
            BG    = QColor("#1e1e2e"); BG2  = QColor("#2a2a3e")
            BG3   = QColor("#313145"); ACCENT = QColor("#89b4fa")
            FG    = QColor("#cdd6f4"); FG2  = QColor("#6c7086")
            LOG_BG= QColor("#161622")
        else:
            BG    = QColor("#f5f5f5"); BG2  = QColor("#ffffff")
            BG3   = QColor("#e6e6e6"); ACCENT = QColor("#2563eb")
            FG    = QColor("#1e1e1e"); FG2  = QColor("#6b6b6b")
            LOG_BG= QColor("#ffffff")
        GREEN      = QColor("#a6e3a1") if dark else QColor("#1f9d55")
        RED        = QColor("#f38ba8") if dark else QColor("#d1383d")
        YEL        = QColor("#cc6a00")
        PURPLE     = QColor("#cba6f7") if dark else QColor("#7c3aed")
        ACCENT_TEXT= BG               if dark else QColor("#ffffff")
        return BG, BG2, BG3, ACCENT, FG, FG2, LOG_BG, GREEN, RED, YEL, PURPLE, ACCENT_TEXT

    def _apply_theme(dark: bool):
        BG, BG2, BG3, ACCENT, FG, FG2, LOG_BG, GREEN, RED, YEL, PURPLE, ACCENT_TEXT = \
            _theme_colors(dark)
        pal = QPalette()
        pal.setColor(QPalette.ColorRole.Window,          BG)
        pal.setColor(QPalette.ColorRole.WindowText,      FG)
        pal.setColor(QPalette.ColorRole.Base,            BG2)
        pal.setColor(QPalette.ColorRole.AlternateBase,   BG3)
        pal.setColor(QPalette.ColorRole.Text,            FG)
        pal.setColor(QPalette.ColorRole.Button,          BG3)
        pal.setColor(QPalette.ColorRole.ButtonText,      FG)
        pal.setColor(QPalette.ColorRole.Highlight,       ACCENT)
        pal.setColor(QPalette.ColorRole.HighlightedText, ACCENT_TEXT)
        pal.setColor(QPalette.ColorRole.PlaceholderText, FG2)
        pal.setColor(QPalette.ColorRole.ToolTipBase,     BG3)
        pal.setColor(QPalette.ColorRole.ToolTipText,     FG)
        app.setPalette(pal)
        app.setStyleSheet(f"""
    QMainWindow, QWidget {{ background: {BG.name()}; color: {FG.name()}; font-size: 10pt; }}
    QTabWidget::pane {{ border: 1px solid {BG3.name()}; background: {BG2.name()}; border-radius: 6px; }}
    QTabBar::tab {{
        background: {BG.name()}; color: {FG2.name()}; padding: 7px 18px;
        border-top-left-radius: 6px; border-top-right-radius: 6px;
        margin-right: 2px; font-size: 10pt;
    }}
    QTabBar::tab:selected {{ background: {BG2.name()}; color: {ACCENT.name()}; font-weight: bold; }}
    QTabBar::tab:hover    {{ background: {BG3.name()}; color: {FG.name()}; }}
    QLineEdit {{
        background: {BG2.name()}; color: {FG.name()}; border: 1px solid {BG3.name()};
        border-radius: 5px; padding: 5px 8px; font-size: 10pt;
    }}
    QLineEdit:focus {{ border: 1px solid {ACCENT.name()}; }}
    QPushButton {{
        background: {BG3.name()}; color: {FG.name()}; border: none;
        border-radius: 5px; padding: 6px 14px; font-size: 10pt;
    }}
    QPushButton:hover   {{ background: {BG3.lighter(120).name() if dark else BG3.darker(110).name()}; }}
    QPushButton:pressed {{ background: {ACCENT.name()}; color: {ACCENT_TEXT.name()}; }}
    QPushButton#accent  {{
        background: {ACCENT.name()}; color: {ACCENT_TEXT.name()}; font-weight: bold;
    }}
    QPushButton#accent:hover {{ background: {ACCENT.lighter(115).name()}; }}
    QPushButton#lang_btn, QPushButton#theme_btn {{
        background: {BG2.name()}; color: {ACCENT.name()}; border: 1px solid {ACCENT.name()};
        border-radius: 5px; padding: 4px 10px; font-size: 9pt; font-weight: bold;
        min-width: 56px;
    }}
    QPushButton#lang_btn:hover, QPushButton#theme_btn:hover {{ background: {BG3.name()}; }}
    QCheckBox {{ color: {FG.name()}; spacing: 8px; }}
    QCheckBox::indicator {{
        width: 16px; height: 16px; border-radius: 3px;
        border: 1px solid {FG2.name()}; background: {BG2.name()};
    }}
    QCheckBox::indicator:checked {{ background: {ACCENT.name()}; border-color: {ACCENT.name()}; }}
    QTreeWidget {{
        background: {BG2.name()}; color: {FG.name()}; border: 1px solid {BG3.name()};
        border-radius: 6px;
        alternate-background-color: {BG3.lighter(110).name() if not dark else QColor('#252535').name()};
        outline: none; font-size: 9pt;
    }}
    QTreeWidget::item {{ padding: 4px 2px; }}
    QTreeWidget::item:selected {{ background: {BG3.name()}; color: {ACCENT.name()}; }}
    QHeaderView::section {{
        background: {BG3.name()}; color: {ACCENT.name()}; border: none;
        padding: 6px 8px; font-weight: bold; font-size: 9pt;
    }}
    QTextEdit {{
        background: {LOG_BG.name()}; color: {FG.name()}; border: 1px solid {BG3.name()};
        border-radius: 6px; font-family: monospace; font-size: 9pt; padding: 6px;
    }}
    QScrollBar:vertical   {{ background: {BG.name()}; width: 8px; margin: 0; }}
    QScrollBar::handle:vertical {{ background: {BG3.name()}; border-radius: 4px; min-height: 20px; }}
    QScrollBar::handle:vertical:hover {{ background: {ACCENT.name()}; }}
    QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {{ height: 0; }}
    QScrollBar:horizontal {{ background: {BG.name()}; height: 8px; margin: 0; }}
    QScrollBar::handle:horizontal {{ background: {BG3.name()}; border-radius: 4px; min-width: 20px; }}
    QScrollBar::handle:horizontal:hover {{ background: {ACCENT.name()}; }}
    QScrollBar::add-line:horizontal, QScrollBar::sub-line:horizontal {{ width: 0; }}
    QGroupBox {{
        color: {ACCENT.name()}; font-weight: bold; border: 1px solid {BG3.name()};
        border-radius: 6px; margin-top: 8px; padding-top: 6px;
    }}
    QGroupBox::title {{ subcontrol-origin: margin; left: 10px; padding: 0 4px; }}
    QStatusBar {{ background: {LOG_BG.name()}; color: {FG2.name()}; font-size: 9pt;
                  border-top: 1px solid {BG3.name()}; }}
    QLabel#credit  {{ color: {FG2.name()}; font-size: 9pt; }}
    QLabel#heading {{ color: {ACCENT.name()}; font-size: 14pt; font-weight: bold; }}
    QFrame#sep     {{ background: {BG3.name()}; }}
        """)

    _apply_theme(_dark_mode_state[0])

    def _C():
        return _theme_colors(_dark_mode_state[0])

    # ── Worker ────────────────────────────────────────────────
    class Worker(QThread):
        row_ready   = pyqtSignal(object)
        log_line    = pyqtSignal(str, str)
        finished_ok = pyqtSignal(int, int, int)

        def __init__(self, entries, letter_map, dry):
            super().__init__()
            self.entries    = entries
            self.letter_map = letter_map
            self.dry        = dry

        def run(self):
            plan(self.entries, self.letter_map)

            # Apply changes oldest-modified-first so that each do_apply()
            # call (which stamps the file with the current wall-clock time)
            # reproduces the original oldest→newest relative order.
            # Entries that won't be touched (deselected, errored, skipped)
            # are harmlessly sorted alongside — their mtime never changes.
            def _mtime_key(e):
                try:
                    return e.path.stat().st_mtime
                except OSError:
                    return float("inf")   # unreadable files sort last

            self.entries.sort(key=_mtime_key)

            c = s = e = 0
            for entry in self.entries:
                if not entry.included:
                    # User unchecked this row in the results list — never
                    # touch the file, regardless of what plan() computed.
                    if entry.status == "pending":
                        entry.status = "skipped"
                        entry.error  = entry.error or T("reason_deselected")
                    s += 1
                    self.log_line.emit(T("log_skip", f=entry.path.name, r=entry.error), "skip")
                    self.row_ready.emit(entry)
                    continue
                if entry.status == "pending":
                    do_apply(entry, self.dry)
                if entry.status == "created":
                    c += 1
                    if not _IS_WINDOWS and entry.lnk_symlink_path is not None:
                        # Linux .lnk→symlink: show the created symlink path and target
                        sym_name = entry.lnk_symlink_path.name
                        if self.dry:
                            msg = T("log_dry_sym",
                                    lnk=entry.path.name, target=entry.lnk_symlink_target)
                        else:
                            msg = T("log_ok_sym",
                                    f=sym_name, target=entry.lnk_symlink_target)
                    else:
                        # Regular letter/mount-path remap
                        display_new = (entry.new_mount_path or entry.new_letter) if not _IS_WINDOWS else entry.new_letter
                        display_old = (entry.old_mount_path or entry.old_letter) if not _IS_WINDOWS else entry.old_letter
                        msg = T("log_dry" if self.dry else "log_ok",
                                f=entry.path.name, old=display_old, new=display_new)
                    self.log_line.emit(msg, "dry" if self.dry else "ok")
                elif entry.status == "skipped":
                    s += 1
                    self.log_line.emit(T("log_skip", f=entry.path.name, r=entry.error), "skip")
                else:
                    e += 1
                    self.log_line.emit(T("log_err",  f=entry.path.name, r=entry.error), "err")
                self.row_ready.emit(entry)
            self.finished_ok.emit(c, s, e)

    # ── Main window ───────────────────────────────────────────
    class MainWindow(QMainWindow):
        def __init__(self):
            super().__init__()
            self.entries         = []
            self.letter_rows     = {}   # old_letter → QLineEdit (new value input)
            self.old_letter_edits = {}  # old_letter → QLineEdit (correctable old letter, Linux only)
            self.old_path_edits  = {}   # old_letter → QLineEdit (correctable old path, Linux only)
            self.worker          = None
            self._root_path   = None
            self._config      = load_config()
            # Accumulated letter map — never wiped on re-scan.
            # Keys (old drive letters) are always uppercase.
            # Values: uppercase on Windows (drive letters), lowercase on Linux (path components).
            def _norm_map_val(v: str) -> str:
                v = v.strip()
                if _IS_WINDOWS:
                    return v.upper()
                if v and not v.startswith("/") and len(v) == 1:
                    return v.lower()
                return v
            self._saved_letter_map = {
                k.upper(): _norm_map_val(v)
                for k, v in self._config.get("letter_map", {}).items()
            }
            # Seed from config so old-path values survive restarts, not just lang toggles.
            self._saved_old_paths = {
                k.upper(): v
                for k, v in self._config.get("old_path_map", {}).items()
                if v.strip()
            }
            self._build_ui()
            self._restore_last_folder()

        def _restore_last_folder(self):
            last = self._config.get("last_folder", "")
            if last and Path(last).is_dir():
                self.entry_folder.setText(last)

        def _build_ui(self):
            self.setWindowTitle(T("title"))
            self.setMinimumSize(900, 660)
            self.resize(1000, 720)

            central = QWidget()
            self.setCentralWidget(central)
            root = QVBoxLayout(central)
            root.setSpacing(0)
            root.setContentsMargins(0, 0, 0, 0)

            # Header
            hdr = QWidget()
            self._hdr_widget = hdr
            hdr.setStyleSheet(f"background: {_C()[6].name()};")
            hl  = QHBoxLayout(hdr)
            hl.setContentsMargins(20, 12, 20, 12)
            lbl_title = QLabel(T("title"))
            lbl_title.setObjectName("heading")
            hl.addWidget(lbl_title)
            hl.addStretch()

            self.btn_lang = QPushButton(T("lang_toggle"))
            self.btn_lang.setObjectName("lang_btn")
            self.btn_lang.setFixedHeight(28)
            self.btn_lang.clicked.connect(self._toggle_lang)
            hl.addWidget(self.btn_lang)

            _theme_key = "theme_dark" if _dark_mode_state[0] else "theme_light"
            self.btn_theme = QPushButton(T(_theme_key))
            self.btn_theme.setObjectName("theme_btn")
            self.btn_theme.setFixedHeight(28)
            self.btn_theme.clicked.connect(self._toggle_theme)
            hl.addWidget(self.btn_theme)

            lbl_credit = QLabel(T("credit"))
            lbl_credit.setObjectName("credit")
            lbl_credit.setContentsMargins(12, 0, 0, 0)
            hl.addWidget(lbl_credit)
            self.lbl_credit = lbl_credit
            root.addWidget(hdr)

            sep = QFrame()
            sep.setObjectName("sep")
            sep.setFixedHeight(1)
            root.addWidget(sep)

            self.tabs = QTabWidget()
            self.tabs.setDocumentMode(True)
            root.addWidget(self.tabs)

            self._build_main_tab()
            self._build_log_tab()

            self.status = QStatusBar()
            self.setStatusBar(self.status)
            self.status.showMessage(T("ready"))

        def _build_main_tab(self):
            tab = QWidget()
            vl  = QVBoxLayout(tab)
            vl.setContentsMargins(16, 14, 16, 14)
            vl.setSpacing(10)
            self.tabs.addTab(tab, T("tab_main"))
            self.tab_main_widget = tab

            # Folder row
            fl = QHBoxLayout()
            self.lbl_folder = QLabel(T("folder_label"))
            fl.addWidget(self.lbl_folder)
            self.entry_folder = QLineEdit()
            self.entry_folder.setPlaceholderText("/home/user/myfolder")
            self.entry_folder.returnPressed.connect(self._do_scan)
            # Persist the folder immediately when the user finishes editing the field,
            # so a manual path change is never overwritten by a later save that still
            # carries the old in-memory value.
            self.entry_folder.editingFinished.connect(self._save_folder_field)
            fl.addWidget(self.entry_folder, 1)

            self.btn_scan = QPushButton(T("scan"))
            self.btn_scan.setObjectName("accent")
            self.btn_scan.clicked.connect(self._do_scan)
            fl.addWidget(self.btn_scan)
            self.btn_browse = QPushButton(T("browse"))
            self.btn_browse.clicked.connect(self._browse_folder)
            fl.addWidget(self.btn_browse)
            self.btn_browse_file = QPushButton(T("browse_file"))
            self.btn_browse_file.clicked.connect(self._browse_file)
            fl.addWidget(self.btn_browse_file)
            vl.addLayout(fl)

            # Recursive
            self.chk_recursive = QCheckBox(T("recursive"))
            self.chk_recursive.setChecked(self._config.get("recursive", True))
            vl.addWidget(self.chk_recursive)

            # "Also detect .lnk shortcuts" — Linux only.
            # On Windows .lnk is the native format so there is nothing to
            # cross-detect; the checkbox is hidden rather than disabled so
            # it doesn't confuse users on Windows.
            self.chk_detect_other = QCheckBox(T_detect_other())
            self.chk_detect_other.setChecked(True)
            # Hidden on both platforms: on Windows .lnk is native (no cross-detect
            # needed); on Linux both .lnk and symlinks are always scanned.
            self.chk_detect_other.setVisible(False)
            vl.addWidget(self.chk_detect_other)

            # Select all / none for the results list below
            sel_row = QHBoxLayout()
            sel_row.addStretch(1)
            self.btn_select_all = QPushButton(T("select_all"))
            self.btn_select_all.setFixedHeight(24)
            self.btn_select_all.clicked.connect(lambda: self._set_all_included(True))
            sel_row.addWidget(self.btn_select_all)
            self.btn_select_none = QPushButton(T("select_none"))
            self.btn_select_none.setFixedHeight(24)
            self.btn_select_none.clicked.connect(lambda: self._set_all_included(False))
            sel_row.addWidget(self.btn_select_none)
            vl.addLayout(sel_row)

            # Results tree — 6 columns, checkbox in column 0 to include/exclude a row
            self.tree = QTreeWidget()
            self.tree.setAlternatingRowColors(True)
            self.tree.setRootIsDecorated(False)
            self.tree.setSortingEnabled(True)
            self.tree.setColumnCount(6)
            self._refresh_tree_headers()
            self.tree.setColumnWidth(0, 190)                              # File
            self.tree.setColumnWidth(1, 130)                              # Path
            self.tree.setColumnWidth(2,  80)                              # Type
            self.tree.setColumnWidth(3, 170 if not _IS_WINDOWS else  75)  # Old drive / Old mount
            self.tree.setColumnWidth(4, 160 if not _IS_WINDOWS else  75)  # New drive / New mount
            self.tree.setColumnWidth(5,  90)                              # Status
            self.tree.sortByColumn(0, Qt.SortOrder.AscendingOrder)
            self.tree.itemChanged.connect(self._on_tree_item_changed)
            vl.addWidget(self.tree, 1)

            # Letter mapping group
            self.grp_map = QGroupBox(T("mapping_title"))
            grp_vl = QVBoxLayout(self.grp_map)
            grp_vl.setSpacing(4)
            self.lbl_map_hint = QLabel(T("mapping_hint_linux") if not _IS_WINDOWS else T("mapping_hint"))
            self.lbl_map_hint.setStyleSheet(f"color: {_C()[5].name()}; font-size: 9pt;")
            grp_vl.addWidget(self.lbl_map_hint)
            self.map_widget = QWidget()
            self.map_layout = QVBoxLayout(self.map_widget)
            self.map_layout.setSpacing(4)
            self.map_layout.setContentsMargins(0, 0, 0, 0)
            grp_vl.addWidget(self.map_widget)
            vl.addWidget(self.grp_map)

            # Bottom bar
            bl = QHBoxLayout()
            self.chk_dry = QCheckBox(T("dry"))
            bl.addWidget(self.chk_dry)
            bl.addStretch()
            self.btn_apply = QPushButton(T("apply"))
            self.btn_apply.setObjectName("accent")
            self.btn_apply.setMinimumWidth(110)
            self.btn_apply.clicked.connect(self._do_apply)
            bl.addWidget(self.btn_apply)
            vl.addLayout(bl)

        def _build_log_tab(self):
            tab = QWidget()
            vl  = QVBoxLayout(tab)
            vl.setContentsMargins(16, 14, 16, 14)
            self.tabs.addTab(tab, T("tab_log"))
            self.log_box = QTextEdit()
            self.log_box.setReadOnly(True)
            vl.addWidget(self.log_box)

        # ── Language / theme ──────────────────────────────────
        def _toggle_lang(self):
            global _LANG
            _LANG = "pt" if _LANG == "en" else "en"
            self._retranslate()
            self._save_current_config()

        def _toggle_theme(self):
            _dark_mode_state[0] = not _dark_mode_state[0]
            dark = _dark_mode_state[0]
            _apply_theme(dark)
            self._hdr_widget.setStyleSheet(f"background: {_C()[6].name()};")
            self.lbl_map_hint.setStyleSheet(f"color: {_C()[5].name()}; font-size: 9pt;")
            self.btn_theme.setText(T("theme_dark" if dark else "theme_light"))
            self._save_current_config()

        def _retranslate(self):
            self.setWindowTitle(T("title"))
            self.lbl_credit.setText(T("credit"))
            self.lbl_folder.setText(T("folder_label"))
            self.btn_scan.setText(T("scan"))
            self.btn_browse.setText(T("browse"))
            self.btn_browse_file.setText(T("browse_file"))
            self.btn_select_all.setText(T("select_all"))
            self.btn_select_none.setText(T("select_none"))
            self.btn_apply.setText(T("apply"))
            self.chk_dry.setText(T("dry"))
            self.chk_recursive.setText(T("recursive"))
            self.chk_detect_other.setText(T_detect_other())
            self.grp_map.setTitle(T("mapping_title"))
            self.lbl_map_hint.setText(T("mapping_hint_linux") if not _IS_WINDOWS else T("mapping_hint"))
            self.tabs.setTabText(0, T("tab_main"))
            self.tabs.setTabText(1, T("tab_log"))
            self._refresh_tree_headers()
            self.status.showMessage(T("ready"))
            self.btn_lang.setText(T("lang_toggle"))
            self.btn_theme.setText(T("theme_dark" if _dark_mode_state[0] else "theme_light"))
            # Rebuild mapping rows to retranslate labels
            letters = sorted(self.letter_rows.keys())
            self._rebuild_letter_rows(letters)

        def _refresh_tree_headers(self):
            self.tree.setHeaderLabels([
                T("col_file"), T("col_path"), T("col_kind"),
                T("col_old"), T("col_new"), T("col_status")])

        # ── Browse ────────────────────────────────────────────
        def _browse_folder(self):
            try:
                start  = self.entry_folder.text().strip() or str(Path.home())
                chosen = _pick_folder(self, T("folder_label"), start)
                if chosen:
                    chosen = str(_win_longpath(Path(chosen)))
                    self.entry_folder.setText(chosen)
                    self._do_scan()
            except Exception as ex:
                import traceback
                traceback.print_exc()
                QMessageBox.critical(self, T("title"), f"Could not open that folder:\n\n{ex}")

        def _browse_file(self):
            try:
                current = self.entry_folder.text().strip()
                start = current if current and Path(current).exists() else str(Path.home())
                if Path(start).is_file():
                    start = str(Path(start).parent)
                chosen = _pick_file(self, T("browse_file"), start)
                if chosen:
                    self._scan_single_file(_win_longpath(Path(chosen)))
            except Exception as ex:
                import traceback
                traceback.print_exc()
                QMessageBox.critical(self, T("title"), f"Could not open that file:\n\n{ex}")

        # ── Letter mapping rows ───────────────────────────────
        def _rebuild_letter_rows(self, letters):
            # Snapshot live values before wiping.
            # Empty field means the user cleared the mapping — remove the key
            # so it doesn't linger in _saved_letter_map and persist to the .ini.
            if _IS_WINDOWS:
                for old_letter, le in self.letter_rows.items():
                    val = le.text().strip().upper()
                    if val and re.match(r'^[A-Z]$', val):
                        self._saved_letter_map[old_letter] = val
                    elif not val:
                        self._saved_letter_map.pop(old_letter, None)
            else:
                for old_letter, le in self.letter_rows.items():
                    val = le.text().strip()
                    if val:
                        self._saved_letter_map[old_letter] = val
                    else:
                        self._saved_letter_map.pop(old_letter, None)
            # Snapshot old-path field values so they survive a retranslate/rebuild.
            # Merge into (not replace) _saved_old_paths so that values loaded from
            # config at startup are not wiped the first time a scan runs (when
            # old_path_edits is still empty).
            for old_letter, le in self.old_path_edits.items():
                val = le.text().strip()
                if val:
                    self._saved_old_paths[old_letter] = val
                else:
                    self._saved_old_paths.pop(old_letter, None)
            # Clear layout
            while self.map_layout.count():
                item = self.map_layout.takeAt(0)
                if item.widget():
                    item.widget().deleteLater()
            self.letter_rows.clear()
            self.old_letter_edits.clear()
            self.old_path_edits.clear()

            if _IS_WINDOWS:
                self._rebuild_letter_rows_windows(sorted(letters))
            else:
                self._rebuild_letter_rows_linux(sorted(letters))

        def _rebuild_letter_rows_windows(self, letters):
            """Classic single-letter mapping rows (Windows)."""
            for old_letter in letters:
                row = QWidget()
                rl  = QHBoxLayout(row)
                rl.setContentsMargins(0, 0, 0, 0)
                rl.setSpacing(8)

                lbl = QLabel(f"{T('old_letter')}:  {old_letter}:   →")
                lbl.setFixedWidth(200)
                rl.addWidget(lbl)

                le = QLineEdit()
                le.setMaxLength(1)
                le.setFixedWidth(80)
                le.setPlaceholderText(T("new_letter_ph"))
                remembered = self._saved_letter_map.get(old_letter, "")
                le.setText(remembered if remembered else "")
                le.setPlaceholderText(old_letter)
                rl.addWidget(le)
                rl.addStretch()

                self.map_layout.addWidget(row)
                self.letter_rows[old_letter] = le

        def _rebuild_letter_rows_linux(self, letters):
            """Mount-path mapping rows (Linux).

            Layout per detected Windows drive letter:
              [Old path (editable)] [Browse]  [old letter edit (1 char)] :  →
              [New path (editable)] [Browse]

            The old-path and old-letter fields are pre-filled from scan results
            but can be corrected if auto-detection got them wrong (e.g. symlink
            target /mnt/x/... correctly shows 'x' but the Windows drive was 'Y').
            The new-path field accepts a full Linux mount path or a single letter.
            """
            self.old_letter_edits.clear()

            # Build letter → detected mount paths index from scanned entries.
            # Collect all candidates, then sort shortest-first so that the mount
            # root (e.g. /mnt/sda1) is preferred over a deep sub-path
            # (e.g. /mnt/sda1/Users/Casa/Downloads/…/user) as the default.
            letter_to_mounts: dict[str, list[str]] = {}
            for e in self.entries:
                if e.old_letter and not e.error:
                    mp = e.old_mount_path or e.old_letter.upper() + ":"
                    letter_to_mounts.setdefault(e.old_letter.upper(), [])
                    if mp not in letter_to_mounts[e.old_letter.upper()]:
                        letter_to_mounts[e.old_letter.upper()].append(mp)
            # Sort each letter's candidates shortest-first (mount root before sub-paths)
            for k in letter_to_mounts:
                letter_to_mounts[k].sort(key=len)

            for old_letter in letters:
                mounts = letter_to_mounts.get(old_letter.upper(), [old_letter.upper() + ":"])
                default_old_path = mounts[0] if mounts else ""

                row = QWidget()
                rl  = QHBoxLayout(row)
                rl.setContentsMargins(0, 0, 0, 0)
                rl.setSpacing(6)

                # ── Old path field (editable) ──────────────────────────────
                le_old_path = QLineEdit()
                le_old_path.setMinimumWidth(150)
                le_old_path.setPlaceholderText("/mnt/c")
                # Prefer the user-edited value from the last build over the
                # scan-detected mount path so lang/theme toggles don't reset it.
                restored_old = getattr(self, "_saved_old_paths", {}).get(old_letter.upper(), "")
                le_old_path.setText(restored_old if restored_old else default_old_path)
                le_old_path.setToolTip(
                    "Detected Linux mount path for this Windows drive.\n"
                    "Edit if auto-detection picked the wrong path.")
                rl.addWidget(le_old_path, 2)

                # Browse for OLD path
                def _make_browse_old(field, fallback=default_old_path):
                    def _browse():
                        try:
                            cur = field.text().strip()
                            if cur and Path(cur).is_dir():
                                start = cur
                            elif fallback and Path(str(fallback)).parent.is_dir():
                                start = str(Path(str(fallback)).parent)
                            else:
                                start = "/mnt"
                            chosen = _pick_folder(self, T("old_mount_label"), start)
                            if chosen:
                                field.setText(chosen)
                        except Exception as ex:
                            QMessageBox.critical(self, T("title"),
                                                 f"Could not open folder picker:\n\n{ex}")
                    return _browse

                btn_old = QPushButton(T("browse_mount"))
                btn_old.setFixedHeight(28)
                btn_old.clicked.connect(_make_browse_old(le_old_path))
                rl.addWidget(btn_old)

                # ── Old letter field (1-char, editable) ───────────────────
                # Shows the auto-detected Windows drive letter; user can
                # correct it when the letter in the symlink path (e.g. /mnt/x/)
                # doesn't match the actual Windows drive letter (e.g. Y:).
                le_old_letter = QLineEdit()
                le_old_letter.setMaxLength(1)
                le_old_letter.setFixedWidth(32)
                le_old_letter.setText(old_letter.upper())
                le_old_letter.setToolTip(
                    "Detected Windows drive letter (visual reference).\n"
                    "Correct it here if the scan extracted the wrong letter.")
                rl.addWidget(le_old_letter)

                lbl_colon = QLabel(":")
                lbl_colon.setFixedWidth(8)
                rl.addWidget(lbl_colon)

                lbl_arrow = QLabel("→")
                lbl_arrow.setFixedWidth(16)
                rl.addWidget(lbl_arrow)

                # ── New path field (editable) ──────────────────────────────
                le = QLineEdit()
                le.setMinimumWidth(150)
                le.setPlaceholderText(T("new_mount_ph"))
                remembered = self._saved_letter_map.get(old_letter.upper(), "")
                le.setText(remembered)
                le.setToolTip(
                    "New Linux mount path (e.g. /mnt/d) or a single drive letter.\n"
                    "This is what the symlink will be retargeted to.")
                rl.addWidget(le, 2)

                # Browse for NEW path
                def _make_browse_new(field, old_mp=default_old_path):
                    def _browse():
                        try:
                            cur = field.text().strip()
                            if cur and Path(cur).is_dir():
                                start = cur
                            elif old_mp and Path(str(old_mp)).parent.is_dir():
                                start = str(Path(str(old_mp)).parent)
                            else:
                                start = "/mnt"
                            chosen = _pick_folder(self, T("browse_mount"), start)
                            if chosen:
                                field.setText(chosen)
                        except Exception as ex:
                            QMessageBox.critical(self, T("title"),
                                                 f"Could not open folder picker:\n\n{ex}")
                    return _browse

                btn_new = QPushButton(T("browse_mount"))
                btn_new.setFixedHeight(28)
                btn_new.clicked.connect(_make_browse_new(le))
                rl.addWidget(btn_new)

                self.map_layout.addWidget(row)
                self.letter_rows[old_letter.upper()] = le
                self.old_letter_edits[old_letter.upper()] = le_old_letter
                self.old_path_edits[old_letter.upper()] = le_old_path

        # ── Config save ───────────────────────────────────────
        def _save_current_config(self):
            # Merge live letter/path fields into accumulated map.
            # If the field was cleared (empty), remove the key so the .ini
            # reflects the reset and doesn't keep the previous value.
            for old_letter, le in self.letter_rows.items():
                val = le.text().strip()
                if _IS_WINDOWS:
                    val = val.upper()
                    if val and re.match(r'^[A-Z]$', val):
                        self._saved_letter_map[old_letter] = val
                    elif not val:
                        self._saved_letter_map.pop(old_letter, None)
                else:
                    # Linux: accept full path or single letter
                    if val and (val.startswith("/") or re.match(r'^[A-Za-z]$', val)):
                        self._saved_letter_map[old_letter] = val
                    elif not val:
                        self._saved_letter_map.pop(old_letter, None)
            # Persist old-path fields (Linux only) so they survive restarts.
            # An empty old-path field means the user reset it — remove from map.
            if not _IS_WINDOWS:
                for old_letter, le in self.old_path_edits.items():
                    val = le.text().strip()
                    if val:
                        self._saved_old_paths[old_letter] = val
                    else:
                        self._saved_old_paths.pop(old_letter, None)
                self._config["old_path_map"] = dict(self._saved_old_paths)
            self._config["last_folder"]  = self.entry_folder.text().strip()
            self._config["letter_map"]   = dict(self._saved_letter_map)
            self._config["lang"]         = _LANG
            self._config["dark_mode"]    = _dark_mode_state[0]
            self._config["recursive"]    = self.chk_recursive.isChecked()
            self._config["detect_other"] = self.chk_detect_other.isChecked()
            save_config(self._config)

        def _save_folder_field(self):
            """Immediately persist last_folder whenever the folder field loses focus
            or the user presses Enter.  This prevents a stale in-memory value from
            overwriting a path the user just typed when some other action later
            triggers _save_current_config."""
            val = self.entry_folder.text().strip()
            self._config["last_folder"] = val
            save_config(self._config)

        def closeEvent(self, event):
            # Persist all settings whenever the window is closed, so changes
            # made without scanning or applying (folder path typed manually,
            # recursive/detect_other toggled, theme/lang changed) are not lost.
            self._save_current_config()
            event.accept()

        # ── Scan ──────────────────────────────────────────────
        def _do_scan(self):
            path_str = self.entry_folder.text().strip()
            if not path_str:
                QMessageBox.warning(self, T("title"), T("no_folder")); return
            if not _HAVE_PYLNK3:
                QMessageBox.critical(self, T("title"), T("no_pylnk3")); return

            try:
                p = Path(path_str)
                self.status.showMessage(T("scanning"))
                root = p if p.is_dir() else p.parent
                recursive = self.chk_recursive.isChecked()
                detect_other = self.chk_detect_other.isChecked()
                entries = scan_folder(root, recursive=recursive, detect_other=detect_other)
                self._populate_scan_results(entries, root, p)
            except Exception as ex:
                import traceback
                traceback.print_exc()
                self.status.showMessage(T("title"))
                QMessageBox.critical(self, T("title"), f"Could not scan that folder:\n\n{ex}")

        def _scan_single_file(self, file_path: Path):
            if file_path.suffix.lower() == ".lnk" and not _HAVE_PYLNK3:
                QMessageBox.critical(self, T("title"), T("no_pylnk3")); return

            try:
                self.status.showMessage(T("scanning"))
                self.entry_folder.setText(str(file_path))
                detect_other = self.chk_detect_other.isChecked()
                entries = scan_single_file(file_path, detect_other=detect_other)
                self._populate_scan_results(entries, file_path.parent, file_path)
            except Exception as ex:
                import traceback
                traceback.print_exc()
                self.status.showMessage(T("title"))
                QMessageBox.critical(self, T("title"), f"Could not scan that file:\n\n{ex}")

        def _populate_scan_results(self, entries, root_path, scanned_desc):
            """Shared display logic for both folder scans and single-file picks."""
            self.log_box.clear()
            self.tree.clear()

            _BG, _BG2, _BG3, _ACCENT, _FG, _FG2, *_ = _C()
            self._root_path = root_path
            self.entries = entries
            self._log(T("log_scan", r=scanned_desc), _ACCENT.name())
            self._log(T("log_found", n=len(self.entries)), _FG2.name())

            for e in self.entries:
                self._add_tree_row(e)

            # Collect mapping keys: drive letters (all platforms) plus old_mount_path
            # for Linux generic symlinks that have no drive letter in their target.
            letters = sorted({e.old_letter for e in self.entries
                              if e.old_letter and not e.error})
            if not _IS_WINDOWS:
                mount_keys = sorted({e.old_mount_path for e in self.entries
                                     if not e.old_letter and e.old_mount_path and not e.error})
                # Merge: letters first, then mount paths (which show full path as key)
                letters = letters + [m for m in mount_keys if m not in letters]
            # Snapshot live rows into accumulated map before rebuild.
            for old_key, le in self.letter_rows.items():
                val = le.text().strip()
                if _IS_WINDOWS:
                    val = val.upper()
                    if val and re.match(r'^[A-Z]$', val):
                        self._saved_letter_map[old_key] = val
                else:
                    if val and (val.startswith("/") or re.match(r'^[A-Za-z]$', val)):
                        self._saved_letter_map[old_key] = val
            self._rebuild_letter_rows(letters)

            if not self.entries:
                self.status.showMessage(T("no_lnk"))
                QMessageBox.information(self, T("title"), T("no_lnk"))
            else:
                self.status.showMessage(T("ready"))

            self.tabs.setCurrentIndex(0)
            self._save_current_config()

        def _set_all_included(self, included: bool):
            """Check/uncheck every row in the results tree (Select All / Select None)."""
            state = Qt.CheckState.Checked if included else Qt.CheckState.Unchecked
            for i in range(self.tree.topLevelItemCount()):
                self.tree.topLevelItem(i).setCheckState(0, state)

        def _on_tree_item_changed(self, item, column):
            """Keep Entry.included in sync when the user (de)selects a row's checkbox."""
            if column != 0:
                return
            e = item.data(0, Qt.ItemDataRole.UserRole)
            if e is None:
                return
            e.included = (item.checkState(0) == Qt.CheckState.Checked)

        def _add_tree_row(self, e: Entry):
            try:
                rel = str(e.path.parent.relative_to(self._root_path)) if self._root_path else ""
                if rel == ".": rel = ""
            except ValueError:
                rel = str(e.path.parent)

            if not _IS_WINDOWS and e.kind == "lnk" and e.lnk_symlink_path is not None:
                kind_label = T("kind_lnk_sym")
            elif e.kind == "lnk":
                kind_label = T("kind_lnk")
            elif e.kind == "symlink":
                kind_label = T("kind_sym")
            else:
                kind_label = e.kind
            # On Linux, show the full old mount path in the "old drive" column so
            # the user immediately sees which mount point corresponds to which letter.
            if not _IS_WINDOWS and e.old_mount_path:
                old_drive_display = f"{e.old_mount_path} ({e.old_letter}:)"
            elif not _IS_WINDOWS and e.kind == "lnk" and e.old_letter:
                old_drive_display = f"{e.old_letter}: (Windows)"
            elif not _IS_WINDOWS and e.kind == "symlink" and e.lnk_source is not None and e.old_letter:
                # Symlink correlated with a sibling .lnk: show the letter sourced
                # from the .lnk (authoritative) rather than the current wrong target.
                old_drive_display = f"{e.old_letter}: (from .lnk)"
            else:
                old_drive_display = (e.old_letter + ":") if e.old_letter else "?"
            item = QTreeWidgetItem([
                e.path.name,
                rel,
                kind_label,
                old_drive_display,
                "",
                e.error or "—",
            ])
            # Checkbox on column 0 lets the user deselect this specific file
            # before Apply, without removing it from the results list.
            # ItemIsEnabled must be explicit — some Qt6 builds ignore
            # ItemIsUserCheckable clicks when ItemIsEnabled is absent.
            item.setFlags(
                Qt.ItemFlag.ItemIsEnabled |
                Qt.ItemFlag.ItemIsSelectable |
                Qt.ItemFlag.ItemIsUserCheckable
            )
            item.setCheckState(0, Qt.CheckState.Checked if e.included else Qt.CheckState.Unchecked)
            item.setData(0, Qt.ItemDataRole.UserRole, e)
            if e.error:
                _RED = _C()[8]
                for c in range(6): item.setForeground(c, _RED)
            self.tree.addTopLevelItem(item)
            return item

        # ── Apply ─────────────────────────────────────────────
        def _do_apply(self):
            if not self.entries:
                QMessageBox.warning(self, T("title"), T("no_folder")); return

            # Validate letter / mount-path inputs
            letter_map = {}
            for orig_old, le in self.letter_rows.items():
                val = le.text().strip()
                if _IS_WINDOWS:
                    val = val.upper()
                    if not val:
                        val = orig_old   # empty = keep same (will be skipped by plan())
                    if not re.match(r'^[A-Z]$', val):
                        QMessageBox.warning(self, T("title"), T("err_bad_letter")); return
                    effective_old = orig_old
                else:
                    # Linux: accept a full path or a single letter for the new value
                    if not val:
                        val = orig_old   # empty = keep same letter
                    if not (val.startswith("/") or re.match(r'^[A-Za-z]$', val)):
                        QMessageBox.warning(self, T("title"), T("err_bad_path")); return
                    if re.match(r'^[A-Za-z]$', val):
                        val = val.lower()  # Linux paths are case-sensitive; keep lowercase
                    # Use the corrected old letter the user may have typed
                    old_le = self.old_letter_edits.get(orig_old)
                    if old_le:
                        corrected = old_le.text().strip().upper()
                        effective_old = corrected if re.match(r'^[A-Z]$', corrected) else orig_old
                    else:
                        effective_old = orig_old
                letter_map[effective_old] = val

            self._save_current_config()

            dry = self.chk_dry.isChecked()
            self.tree.clear()
            self.log_box.clear()
            self.btn_apply.setEnabled(False)
            self.btn_scan.setEnabled(False)
            self.btn_browse.setEnabled(False)

            self.worker = Worker(self.entries, letter_map, dry)
            self.worker.row_ready.connect(self._on_row_ready)
            self.worker.log_line.connect(self._on_log_line)
            self.worker.finished_ok.connect(lambda c, s, e: self._on_done(c, s, e, dry))
            self.worker.start()
            self.tabs.setCurrentIndex(1)

        def _on_row_ready(self, e: Entry):
            try:
                rel = str(e.path.parent.relative_to(self._root_path)) if self._root_path else ""
                if rel == ".": rel = ""
            except ValueError:
                rel = str(e.path.parent)

            if not _IS_WINDOWS and e.kind == "lnk" and e.lnk_symlink_path is not None:
                kind_label = T("kind_lnk_sym")
            elif e.kind == "lnk":
                kind_label = T("kind_lnk")
            elif e.kind == "symlink":
                kind_label = T("kind_sym")
            else:
                kind_label = e.kind

            if not _IS_WINDOWS and e.old_mount_path:
                old_drive_display = f"{e.old_mount_path} ({e.old_letter}:)"
            elif not _IS_WINDOWS and e.kind == "lnk" and e.old_letter:
                old_drive_display = f"{e.old_letter}: (Windows)"
            elif not _IS_WINDOWS and e.kind == "symlink" and e.lnk_source is not None and e.old_letter:
                old_drive_display = f"{e.old_letter}: (from .lnk)"
            else:
                old_drive_display = (e.old_letter + ":") if e.old_letter else "?"

            # For Linux .lnk→symlink entries, the "new drive" column shows the
            # full Linux target path the new symlink will point to.
            if not _IS_WINDOWS and e.lnk_symlink_path is not None:
                new_drive_display = e.lnk_symlink_target or e.new_target or "—"
            elif not _IS_WINDOWS and e.new_mount_path:
                new_drive_display = e.new_mount_path
            else:
                new_drive_display = (e.new_letter + ":") if e.new_letter else "—"
            item = QTreeWidgetItem([
                e.path.name, rel, kind_label,
                old_drive_display,
                new_drive_display,
                e.status,
            ])
            _BG, _BG2, _BG3, _ACCENT, _FG, _FG2, _LOG_BG, _GREEN, _RED, _YEL, _PURPLE, _ = _C()
            colors = {"created": _GREEN.name(), "skipped": _YEL.name(), "error": _RED.name()}
            col = QColor(colors.get(e.status, _FG.name()))
            for c in range(6): item.setForeground(c, col)
            self.tree.addTopLevelItem(item)

        def _on_log_line(self, text, tag):
            _BG, _BG2, _BG3, _ACCENT, _FG, _FG2, _LOG_BG, _GREEN, _RED, _YEL, _PURPLE, _ = _C()
            colors = {"ok": _GREEN.name(), "skip": _YEL.name(), "err": _RED.name(), "dry": _PURPLE.name()}
            self._log(text, colors.get(tag, _FG.name()))

        def _on_done(self, c, s, e, dry):
            self.btn_apply.setEnabled(True)
            self.btn_scan.setEnabled(True)
            self.btn_browse.setEnabled(True)
            self.status.showMessage(T("done_dry" if dry else "done", c=c, s=s, e=e))
            self.tabs.setCurrentIndex(0)

        def _log(self, text, color=None):
            _BG, _BG2, _BG3, _ACCENT, _FG, *_ = _C()
            if color is None: color = _FG.name()
            cursor = self.log_box.textCursor()
            cursor.movePosition(QTextCursor.MoveOperation.End)
            fmt = QTextCharFormat()
            fmt.setForeground(QColor(color))
            cursor.setCharFormat(fmt)
            cursor.insertText(text + "\n")
            self.log_box.setTextCursor(cursor)
            self.log_box.ensureCursorVisible()

    win = MainWindow()
    win.show()
    sys.exit(app.exec())


# ── CLI fallback ───────────────────────────────────────────────
def run_cli():
    global _LANG
    parser = argparse.ArgumentParser(description="Drive Letter Changer Z")
    parser.add_argument("directory", nargs="?", default=".")
    parser.add_argument("--map", "-m", action="append", metavar="OLD:NEW",
                        help="Drive letter remapping, e.g. C:D")
    parser.add_argument("--dry-run", "-n", action="store_true")
    parser.add_argument("--lang", choices=["en", "pt"], default="en")
    parser.add_argument("--no-recurse", dest="recursive", action="store_false", default=True)
    parser.add_argument("--detect-other-os", dest="detect_other", action="store_true", default=False,
                        help="(Linux only) Also detect Windows .lnk shortcuts in addition "
                             "to the native symlink scanning.")
    args = parser.parse_args()
    _LANG = args.lang

    print(f"=== {T('title')} — {T('credit')} ===\n")
    root_path = Path(args.directory).expanduser().resolve()
    print(T("log_scan", r=root_path))
    entries = scan_folder(root_path, recursive=args.recursive, detect_other=args.detect_other)
    print(T("log_found", n=len(entries)))
    if not entries: return

    letter_map = {}
    if args.map:
        for spec in args.map:
            parts = spec.split(":", 1)
            if len(parts) == 2 and re.match(r'^[A-Za-z]$', parts[0]) and re.match(r'^[A-Za-z]$', parts[1]):
                # Keys (old letters) always uppercase; values lowercase on Linux (path components)
                letter_map[parts[0].upper()] = parts[1].upper() if _IS_WINDOWS else parts[1].lower()

    plan(entries, letter_map)
    c = s = e = 0
    for ent in entries:
        if ent.status == "pending": do_apply(ent, args.dry_run)
        if ent.status == "created":
            c += 1
            if not _IS_WINDOWS and ent.lnk_symlink_path is not None:
                if args.dry_run:
                    print(T("log_dry_sym", lnk=ent.path.name, target=ent.lnk_symlink_target))
                else:
                    print(T("log_ok_sym", f=ent.lnk_symlink_path.name, target=ent.lnk_symlink_target))
            else:
                print(T("log_ok", f=ent.path.name, old=ent.old_letter, new=ent.new_letter))
        elif ent.status == "skipped": s += 1; print(T("log_skip", f=ent.path.name, r=ent.error))
        else:                         e += 1; print(T("log_err",  f=ent.path.name, r=ent.error))
    print(f"\nChanged: {c}  Skipped: {s}  Errors: {e}")


# ── Entry point ────────────────────────────────────────────────
if __name__ == "__main__":
    if "--no-gui" in sys.argv:
        sys.argv.remove("--no-gui")
        run_cli()
    else:
        try:
            _ensure("PyQt6", "PyQt6.QtWidgets")
            run_gui()
        except Exception as ex:
            print(f"GUI unavailable ({ex}), falling back to CLI.")
            run_cli()
