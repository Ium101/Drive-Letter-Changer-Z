#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
#  build.sh  —  Drive Letter Changer Z setup
#               Generates icon, creates desktop shortcut and app menu entry
#  Run:    chmod +x build.sh && ./build.sh
#  Output: drive_letter_changer_z.ico   (icon, lives next to the .py)
#          Desktop shortcut             → runs drive_letter_changer_z.py
#          App menu entry               → runs drive_letter_changer_z.py
#                                         (Utilities category)
#  XDG:    ~/.local/share/icons/hicolor/*/apps/drivechangerz.png
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
# Per-size PNGs go under hicolor/{size}x{size}/apps — the icon
# extraction step below creates each size's subdirectory as needed.
ICON_DIR="$HOME/.local/share/icons/hicolor"
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

# ── Icon ─────────────────────────────────────────────────────────
# drive_letter_changer_z.ico is the single canonical icon asset --
# the exact same binary file build.bat embeds and uses as-is for
# Windows shortcuts. It's a multi-resolution .ico (16 through 256px,
# PNG-compressed frames inside). Here on Linux we just base64-decode
# it to disk next to the .py, then pull each embedded PNG frame
# straight out of it (pure Python, no Qt/rendering involved) and
# drop them into the hicolor icon theme at their matching sizes.
echo " Installing icon..."
ICO_B64=""
ICO_B64+='AAABAAcAEBAAAAEAIAAbAgAAdgAAABgYAAABACAAFwMAAJECAAAgIAAAAQAgADgEAACoBQAAMDAA'
ICO_B64+='AAEAIAACBgAA4AkAAEBAAAABACAAuwYAAOIPAACAgAAAAQAgAIwNAACdFgAAAAAAAAEAIADbGAAA'
ICO_B64+='KSQAAIlQTkcNChoKAAAADUlIRFIAAAAQAAAAEAgGAAAAH/P/YQAAAAlwSFlzAAAOxAAADsQBlSsO'
ICO_B64+='GwAAAc1JREFUOI2dkk1IlFEUhp/7edOvL2WyP4kCZRYtCiIRW2QgLYQKKoqQWgSuAhdtUiEi2rtq'
ICO_B64+='YQgSpARREEUtXLTqzxK0iGoCcRU02qZJnIGZuT/fd9roNBENOAfu5p73OeflvVcBXHp+b8tKPh5p'
ICO_B64+='CIIehBZqlaIQJ8nbnKyMzvZfLamuiYmoLaXnFeyvCf5T8vVXkO/WW0M/5FyyQRiAA1HSNKytdT0q'
ICO_B64+='UHXwIMIR7X3cDFLXAFAt2ppyhQ71Jm709kHyZ2Bm6TsPFzP/NRGUnRPjLMZZStbwZTnL5+UsThKO'
ICO_B64+='H+zErvXSqVZSDZp1rXGWsnMSOGPFGIsxlkKxyJ35dzxbyNDdnubJ3CyTn95jjOXW6X5OdOxjXWuM'
ICO_B64+='xRkr2lor1Rk0ac342Qss5X5ybfoxfu3+8oNJcoU8ztrqDCQQ7xEfV87oyXO0b9/JzaeP2BZGtOpG'
ICO_B64+='xMccatvD7s3Nf2nFe3SSxBUD6R27ONN1GIDpoesAzC0ucP7uOIPH+rj/+gUffmSrDIDaOzz4EqG3'
ICO_B64+='vlfklRYb56nvHwGs6jj2bxTqVD20IDNaNxZu+1J0EejcIP8xLKsxBdAxMBAWtb+CcFQpUjW3Cqso'
ICO_B64+='ZiKvx75NTZV/Azca6noHQgquAAAAAElFTkSuQmCCiVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYA'
ICO_B64+='AADgdz34AAAACXBIWXMAAA7EAAAOxAGVKw4bAAACyUlEQVRIibWTTWiVRxSGn/PN3Ou9l/xoMZFQ'
ICO_B64+='A1JosKEkBV3YRYoSpSmtSqGkXRQL9ie6UizBoAsbSLoRggE1SWtLlS6kiFHpptA2ZCE0LQqR0hYX'
ICO_B64+='oqVUYyJq/U2+mTkukhjvzUc13OSF2cw75z3nvOeM8ATePn7kZW/s6xJF9QgZ5gLloYYwbLz7of+9'
ICO_B64+='j36fvhaAT/r6Uv8ssZ1GzC4BMyfhWXnwXn3X8ptu7xctLbEFuFIqHcaHVk8oRnsaBmi9UiIBaJPG'
ICO_B64+='b3trI+VCsZUXQsEHoc7GcbzBiMyr+BRMCGG9DbGrU4kWQB8UrbPehwziFyQBKlnrvNOFUZ9MYWM3'
ICO_B64+='oUK+RdlUiubaV1DnEqOOnhtCMumnqxPUuthDwXqWpzPsWLshOUiVI4M/IabsWRrAOu8CBSaN3rnN'
ICO_B64+='xr5uVCcTP5cr4VDz+5RmsnR934/LpBEX01TzEiYoP178g/EoYVGEYN1EzNSHfgwH/HX9GgApY/is'
ICO_B64+='aTOlmSxnfv2Fw0NniRalITg633qHXDrNmn1t3LNJn1Sx3vv/HXLHG5tZveIFLly+ROup42g6hfeT'
ICO_B64+='s7k0OkLWWCaCw3tJClerXqHQoylsfbWBd1evYeTWTT78qocJY8DPVLqx98DM48Q6BRvUIzqbfO3F'
ICO_B64+='lexp2sR4HLO1p5vREM96U7usikjhz5GrJDWgIli8QzWfrSpfzMHmLZgo4t8bY7Q0NuWNqb3/O8aC'
ICO_B64+='48S2neTSi1i1ewdjktCBKFadQgH5fPkSynI5AKorKqmuqMzj958+gbow42xQVBKGrCDVn27/RpUP'
ICO_B64+='ZrPFQ4SjNjj3AEncgKKhcN/iGU5sbx4g6LBF+Vk1OMDOs74TzIC589v5GyWr6iNU16LKvJ0Q2q/2'
ICO_B64+='fH3SANx9c/HZ3H+lHmhANSpS3GkI7SNVf3/O4OWQN92lH2+piUJYB9SD5ubmiNwHhkMUDYx9eezi'
ICO_B64+='9O0jJddp0euUP6oAAAAASUVORK5CYIKJUE5HDQoaCgAAAA1JSERSAAAAIAAAACAIBgAAAHN6evQA'
ICO_B64+='AAAJcEhZcwAADsQAAA7EAZUrDhsAAAPqSURBVFiFxZZtaJZVGMd/132f59kzdZtN25pZQyJKemHN'
ICO_B64+='SZAZhlBott7MCYXahgn6sT4FQiBFVFBayQyxTbIXv6W4DBoxVyooSikMsaIyqj06Ibf25PPc17n6'
ICO_B64+='sBf34nOvtTb/cOA+51z39f9fL+fctzASZvLop001zrnFJlZuIsEom3FAzLyYdEZR1L6/bt1xRGzY'
ICO_B64+='/tDJI5/snh86bRZk4URI88GwYxqFaw+sXtMxSsCyj3fWh0HwHpCaDPIrkIy3aFPL6vUfDAp46KMd'
ICO_B64+='t4cSnMAonFzyAQ1kLAzuObiq4UyAmZhqk6oWqlemZKgWajbbhJnIg01bFwSSOD4lkY+AqV/gvJdF'
ICO_B64+='hl4Lfgy736lqmQw/DFMpoMyp+uDa0INB4DTKTfSu+e8CzJvzZobP3wML51aScolYR3/0XOLshfT4'
ICO_B64+='FQjmNKdmMTXYvHQ5FcUlsX4+++4EL7e2gIyvmGKY896jWF6jrp5uEldp0tnFxYPPP507Ry6bRZwb'
ICO_B64+='l4AQwXlTM59fwMrGt8l2XRy2tvHhFbxY+yQAR8508O7n+0jOnQOq1N5RRUVxCWqenUfbYwX4QMzl'
ICO_B64+='cpHlpwcKU33O+7H01vm8UPsEAD+fT7OhcRuUzkTNQJWVd1dTfVMl2Shie+sXBKmCvK5FMecjj48p'
ICO_B64+='wVDcVnYDb9Q+jSB0ZzI8t/VNul2ISyTRqK+Rzft+ayP3Vy8upiwBgos0F5+BfpROn05j3RqmJZN4'
ICO_B64+='MzY1buPsn10kZpWiGg3aNR1uo+XoN0TqUY2QIXsj4cGcN89YCUiEIY2r1jJ35nUAvLJ3D60dp0mW'
ICO_B64+='Xz8k4j7sP3US7c30RVhQMGp/KEzA4cHGyMGWx56ipnIeAHu/bmP7wQMkK8oxA0a+G4SEM2ZcIYlp'
ICO_B64+='cBHB4f1oJ0PQsGgJdQvuBeC3rgt8+NWX1FRVDTtyvbks36c7AWhet4Hqm+dxOcpR8+rm2MAQwXnv'
ICO_B64+='yVeDVCLBS8tqB+dzZs1m3+Yto+xO/foLK955HYKAaYkkRakUBVFIdOkSYdGMUfYDMOvPQL74AxPC'
ICO_B64+='YOzvhM/l0MxlgsLUlWwamPr4EmADGbg6ev7OULH+WbS7Z0wRidmzMO95/K3XyJ2/AIArKYlvQujv'
ICO_B64+='gRi44iJccdGYAgDwniCZoODGimFrsf7Ne+Ua/ZCAqUNJm8SrnCyISdpJ5I9Y+O+u4v9dAHpYAKnY'
ICO_B64+='2NAGtniK+Q/9vn3XEgdYBPWh+W+BaVNE3uvV6gELAXqPnbw4veauHzGWY5bAjEkcveAb0jt2t8OI'
ICO_B64+='9i97fu0teN0lIg9MRthmdoggrE+/3/zDwNrVzp+Ur3vmTgvlPoQyIJwgr2KkRe1wZ9Oe04y49/8B'
ICO_B64+='Tb0xQaYo6FEAAAAASUVORK5CYIKJUE5HDQoaCgAAAA1JSERSAAAAMAAAADAIBgAAAFcC+YcAAAAJ'
ICO_B64+='cEhZcwAADsQAAA7EAZUrDhsAAAW0SURBVGiB1ZppbFRVFMf/576lyxS7TTspiywWgukHZFEBQUpc'
ICO_B64+='AtQFcQUShIbNpKZAXMIHPhhEEgJoAhUKaqMxagQBq6BIXBqNEFACaApEgRZoLUuhQGE6M+/e44fp'
ICO_B64+='TDttp/MeBTr9JS+Ze+697557zzl3e0OwweQvP8oyBPdn1rPslO8qRNaFgKLq714ovBCzbLSMqds/'
ICO_B64+='HyBV0xINWgHAg26tirY5IaF2GYnmmm0FM6s7KtCuA/NLS43aNGOlpokiAAm3XUUbKKCJpSrp3RBY'
ICO_B64+='umnBgkDrvIgO5JeVpaW4eAcBE+6sivZgoKLxOk39Zc6chpAs3IH5paXGmbvEHkEiLpUPoVhV9Luq'
ICO_B64+='HgtZQg9lVLnECo0xQbHqPu3sMaHKJVYAeANotsCksg0D2BTHmOPD52NBhKYAtKE/zZxbrQOApcli'
ICO_B64+='Uj1DeQBgRqLgwCIAi3UAYEkFiuLeddpAUwAspvzS1W4YCTEXjHhE08itK83sh/gP3I5Rej9dKSsT'
ICO_B64+='FHVBjmuU9Ln14I+eaQEhCDosCe6hFoCloFuWBda07lblpmApoVsAoHqmCwGALgOKhQMD/DCvGEmG'
ICO_B64+='6bihN3d+hd+rTzqu1xlKgnUAkA6m0STDQJJhOG7Md/4CLGmBhHBcNxoEAV0KxXfChRq9Xiilop+g'
ICO_B64+='bgbRbAHloAPLvt0G1XA1av79g4dg+rj8CNnWvb9h7/GjcA28G3wLB0sIAV36A8zMtivtOvo3pNfb'
ICO_B64+='YV7f9AwsGzEzQvbniX+w9NMyGBnpUIoBBNsqfHAcRvdvOaluOfwH9hyvdNQBVoHmGHAyKgRQclI7'
ICO_B64+='sctMQOmseUhPdoVlNZfqMbfkPajkRGiu5Ih2hmR58NDA3HC64sghWD4/yNBhF13TguuAcmCBjhBE'
ICO_B64+='WP3U88h1Z4dlN3w+FK5bg0uWHwkZWe3ctK3VlT8AaVkQmv0gt5ihWxaALm6lX390CiYOHhqhXPEH'
ICO_B64+='76OytgZmbw8Uq5DnRJRpm1ZKOVqTFGvQpfJzV2aGZ4aNxLwxD0fIVm/fgp0HDyAhxwNmBkvZrt7h'
ICO_B64+='s6eh+wNAc0f+ra2BUhLooGw0GDIYA06CuDXD+/bHyiefi5CV79+LteXbYHrcgKZFfXfZvl+xqf5y'
ICO_B64+='xIjr6anOdCGCDgmAnHcgJzUNm6bPhqm3BN2RqpMo3lwCIz0VIiEhPLrRMDLS2guddEARdMACO3Si'
ICO_B64+='JMPE5hmFcKf0CsvOX2nAy++ugt80YKS4btqqTiBYzdcqyn5jRIS1z05HXk6fsMwXCGD22lU4d70R'
ICO_B64+='pifL1vtGD8zFgEx3OH3oTDWOnfvPgfoABKDDAtiBCy15ZBIm5w2LkO08sA+ezEwU5A4CRTlbVF+6'
ICO_B64+='iGN1LQq+NGo0pt43Mpx+e8dWVNaedbRXIouaLWDT3PdkefDqxMfbyaeNHY9pY8d3WvfDih/x1tnt'
ICO_B64+='oPDZI7JNeeMGOBAAmU52ugTdggWyGQPJphl1hGOhvE1QPh9EUnAV73DMmB3FjkVW0IVsz0IOYqUd'
ICO_B64+='zIDq5B3MwTwnbTBAfV8ryieon+3WkdcaYTVcsd9IKwx3JkRSYjjtr62LWORMTzbItH/WYIiJjqdR'
ICO_B64+='keKCmeKKXTBao61cxMjxdJofE7KcBXHcQaFptO1Oq4dAiqCDVD166KUEMV3UAVnDfOsO2ncSClAN'
ICO_B64+='AUDvormVINzb3Qo5gypr123OC26nob6Gop7VAVLlQPM3MkGiRCm5CEBip5XiB68m5XoA0ADg2v6D'
ICO_B64+='V1NGDTcBjusvlC3QytqNH5cDQDh667JPLQdjN5gR1w/4+7rsU8tDerfcilZUKXNMXrkmaQQzchG6'
ICO_B64+='womjh4DdfkO+6F31TfhiKuJa17v/L1/jE+lf9Lp2FwA8AMD5JejtwUtE79TlnF7YWnmgkz97ZC6c'
ICO_B64+='1Ue3uEiBnyZ00xRLqCSmckun9fUbP6npuIgNUl+ZkZ7o1/oQsTt26a7DTBebTFlzZcNnl2OV/R9g'
ICO_B64+='HL1/r6xdGQAAAABJRU5ErkJggolQTkcNChoKAAAADUlIRFIAAABAAAAAQAgGAAAAqmlx3gAAAAlw'
ICO_B64+='SFlzAAAOxAAADsQBlSsOGwAABm1JREFUeJzlW1tsFFUY/v7ZW5fS0tbCdluQGBWJERAwElBS2SCg'
ICO_B64+='3EKBCuVSWpSoRR68vMCDaKIPgKBC5U7BhouA0ACWEAkYEEojQQxREUlTgvQChdDSli7snN+H3W27'
ICO_B64+='nW136czO0O6X7MP+/+ycb/7z386Zs0CUg8K6ipkmHfz+FYl5ugTTSICdRNQbgD2y9MLGfWa+BVCl'
ICO_B64+='gFwCYP+hjOyzIOJQP+zYAMw0+cD2bAmm5QTurxVbPcCgawLy8sMZC3Z0ZIh2DTBpf8FAEthDREMi'
ICO_B64+='Q1E3XBTEs4/MyLkcTBnUABN3b5lIJmkXAfGR5aYPGKgFy1lH3nqnuK1OYYAJOwveNJvFIQZM+tDT'
ICO_B64+='B8yQGZh8dNbCo63lAQaYsHfrcyREKTF66UtPJxDuAjyieNaiK36R1KxkJn4o9kCgFzPQLT8CCULQ'
ICO_B64+='HjBTi018GLtzw3yJaYdus2EgmGj+z3MWFQJ+D2AmkvGZ8VOk00cWn/u9gADAtS1/lGSiM4ZNiQHw'
ICO_B64+='CM/IX3KWnDN7v3KGCNkzdS9IZJoOwGsAmcRIEuF1xd0FTDwKALweIOAEoswFmFIAnwEEsyO65h8A'
ICO_B64+='2AH4DMBC9Iiy+QeAWKDFA4ylYiC8HsDCaB6GwR8CRvMwDN4yGPUhEG1dUCt4+wAVHjB32Aj065Wo'
ICO_B64+='CZnCC+fwX+1dTe4VLrwhoCIHpD/1LF5M7asJmYMlp/HQ7YZksWhyv3CgQRXQLnw89Q0Qnocgs36b'
ICO_B64+='Ud4+4DGpArJgCCFAOvLxGaDzs3jtzm3EgMJKpCZJwoDUtKC6s5f/wu9lV2Fx9gHpmJRVV4FlxUVw'
ICO_B64+='36qBcD8Ife20zKAGuHarGnmb88FWKySLTdeqpEknaE1OCnnNtEFDkTtmrEJe33QfC/O/Rq27CTGp'
ICO_B64+='TjBEQFpZ/KoLC14eFfCbuqYmuL5bpYqzH6qrQDgY3rc/Ph0/RSEXzMjbmI9/KytgS0uBIABtuJhN'
ICO_B64+='EuwWa4DM45FRX34d9ieDh9OjIOKNUGp8Ar7NyILFpMzsX+zbjZOX/oA1pTfIZA7OIyg1BsuyJrwj'
ICO_B64+='uhiyW6xYnzkXT8TGKnT7zpzCpmM/wZKUACnG1i4HbqdJY2ZNeEesDBIIK6fOxECHU6E7f/UKPtmx'
ICO_B64+='GVKsHVJczw7Hb98AQhPePg9QfR8FPnSNw7iBLyjkN27XIHftV/BIJtiSkkKO3eB2o+ZeXYAh7jU2'
ICO_B64+='Nu9wq4VvQ0RbD5gyaCjeH+1SyBvdbmR/swo1DQ2wOvtAIPRTrD11HGsOH4BcVx+okEgT3qoXQ20x'
ICO_B64+='OK0fVkzNVMiZGR9sWoc/r5fDmuIASVLY45rj42COj1MqNOCtqQEccfHYNDsHNrNZoVt5cC+Kz5fC'
ICO_B64+='0jsZksUcmbjrBHw5QD0Zm9mMjVk5cMQpjxQcKi3B6qIfYU6Ih2SP0WQ8raCZB6ycNgtD0p5UyC+V'
ICO_B64+='l2HJpnUw9bB73fgxenig2QDqbrL4tdcxZfAwhfxm7V3MX70CDwBYkxI7Nc6i0WMwp00rXN/kxsR8'
ICO_B64+='DVthNS45/vlB+GjsG0F1xy9ewLhhL8HUK86b9ELgn+pK/FZeFiBLtMeif1JygKzufiPcFVWwOh2d'
ICO_B64+='5u2HqhCIj7FjTeZcEAV/r5SV7kJWurIctoftp06i9PLfkGyte//g7TF7PMZXgVirFbFWm2oSfoim'
ICO_B64+='JoiGBkjWMLbENOqEVIVAJLK5t8fn1oJ2rtNmfHVVIBIZPdyZ1cgDCAD6fZzX6TuxLONBRZVqIn6Y'
ICO_B64+='esbCnJgQIPPU1kGuuxd4oSTBlqZcaD0Krq/KJ/WNkCTB2jdVFZG2aMvHFB8HU5BW2PgQ6AbwnxEy'
ICO_B64+='loWB0Gwt0FXhD4EG+E5MRBHqgRYPqATwjKF09Ecl4DMAMW5wlBmAgAqg5dXYr0RIN5aSvhDg00Bz'
ICO_B64+='FRBFzLTMSEK6Q6IioOW0OKXk5V6hKAkDBq5W5W8bAIDNLTIsA/MPBvLSD8xL4Wt+Wi/kKeW9BSUA'
ICO_B64+='RhhCSj+UVq3fPhI+A7TepmEh8xww7oB96u73uSNAWf6HB4L8acrxbo6LWBxDc4LsNvAwSeOrNxSc'
ICO_B64+='aC0MupfleHueCxLtAxD6xX/XwB0Inlm9pfBEW0W7h8T7LMp+mljsRNfPCaXskbNuFuwqC6YMdUqe'
ICO_B64+='UhbOm8HEX6LrlcirxLS0amvhfnSw3A33bwKUnDtvOJGYKhGNZuZUAE4APbVgqgHqAVQSUYVgPs3E'
ICO_B64+='RTVbdl1ANK/zw8X/G8iqM/6sBpMAAAAASUVORK5CYIKJUE5HDQoaCgAAAA1JSERSAAAAgAAAAIAI'
ICO_B64+='BgAAAMM+YcsAAAAJcEhZcwAADsQAAA7EAZUrDhsAAA0+SURBVHic7Z15dFTVHce/v/vmzWSZkGWy'
ICO_B64+='kCAqPSCLtCAotdgqHkRkOYgWobJowSBqW6xae6zHNsWqpS2yGYSw6wlYFu0BU1DRlqVFz1HUYiNQ'
ICO_B64+='RdEAWQgJIQtJZub9+sckwwSSzLzJzLw3mfvJeee8l7m/+373vvvu8rv3/S4gkUhiFwpXxA8WFKil'
ICO_B64+='GfEjiWkUQRtIRH0FUQ4DiQASCLCE697RCAMuAA0E1GvMp5n5S4Y4wsR7s89cOLh63jxnOO4b0gIw'
ICO_B64+='btdym1KX8mNF4RkK6GYG7KGMP1YhoM4N3u920ya3/dzru8fPbwph3F1n9OY1WYk29SkBmg0gORRx'
ICO_B64+='SjqkRgNvqG9yLnxv+tzyrkbWpQIwrrCwh8XmfA6guYIorqvKSAJHY24EsJqs7md23vlAbbDxBF0A'
ICO_B64+='xm1dP00VYgkB2cHGIek6DJQ6Ne2x3VPnbAlGXn8ByMsTEwf3WSKA+cHcUBIeNOZlRcUnHseCBZoe'
ICO_B64+='OV0F4LatBck2VrYJEmP0qSeJBKzxO43CNfXdqfNqApUJuABM3L6hH9woIvA1wakniQQM+h8UTCya'
ICO_B64+='MvuLQMIHVADGbN/Qz6rx+2B2dE09SUQgOuuCduPbU3O/9BdU+Atw29aCZNXlLpIPP4pgdigaim7b'
ICO_B64+='WuB3SK50+mtenrjG0WMHgUaAAXlE0QGkk0bXfTl42Gbs28ftPV7ATw0wduAVLwrQ7canRh7BHIIw'
ICO_B64+='dmz/nBfbfbgtdNgHGF24appVKH/tTFgSHTjdrmnvznp4a3u/tVsAJu1Yl9RU5zpGRNLI0w1g5lKb'
ICO_B64+='3dK/PYthuzNyDTXOZ4WgbOYOmw5JdJHdUON8FsBjl/5wWQ0wevOaLIW1r8EcHxHVJJGB6IKbRJ9L'
ICO_B64+='J5AuqwGE2/lrQMiH391gjic4fwXgSd9/t6kBxu1abnNWWsuIOCWiykkiAjOdU9Obe/quJ2hTA1wo'
ICO_B64+='o8mqhVMgm/5uCYFTGivEnQC8I4I2BUAIZYbs+HVvCGImfAqAtwkYlZdnEX0yqyGXcXVvGLXaiYq0'
ICO_B64+='vQsWuADfGuDK1BsZLB9+d4eQ5O6d8n0A/wZ8CwBbRsm2PzZQoN6KywqAog1gDtsqcYmJYKH1bz33'
ICO_B64+='FgDW0I9IVgGxAEP0az33GQVwL1kDxAYE7tV67i0AGrOd5POPCdhnpHexCWBOkJ3A2IDBia3nvoYg'
ICO_B64+='lWUJiBXU1hOfYaAhikgM5mITIEtATOIzDJQFIBbxHQYap4XEMHxGAUaqITEK32GgkXpIDEIWgBjH'
ICO_B64+='76dhku6NrynYSD0kBiGbgBhHDgNjHMNNwemJdqQlJPoPGGEq62pRdaHBaDXCjuFNwE+GXI/7h99o'
ICO_B64+='yL07I//gXmz86H2j1Qg7hncCzdr30FwuuBqbQBYFpHTuRiGakcPADnCeO4+GklNwng/aBV9U4NME'
ICO_B64+='6PIuFjLMOgvJYDBrYGbD8iYSGD8XYM7nD7AnT1qP7orPKKAbpzIoWlytdPMSYPiCELM2AS5Na9GM'
ICO_B64+='TatjKLg4CjCqmTNh3n5zpgJb/nUArAEaG5g3EcDHEmhMKovLT2NH8afQmpqhNTeHNO5EWxzuuO56'
ICO_B64+='XTK1Fy4g9+UlqGlo7f0zjMqbSGC4JfCdo8V452gxmquq4awO2MWtX4gIK+f9QpeMW9Mwf+3LOF5a'
ICO_B64+='CgAQqgpLkt2UtVSoMNwS2ApZrVCSQmcSfvyOSbh96DBdMgvf2IK9xYc9+ggBa88MgMjwvAknpikA'
ICO_B64+='SkI8lITQuCYaP+i7eHj0WF0y2w4ewJo9bwHwOE2wZqSDLBa/+WK32bBr7qMB3aOstgZTXynQpVe4'
ICO_B64+='6XYbNw3O7oXnxt2lS+aj41/g6U0bvdeqIzXgwkggOBIDc6vQ5Hbp0isS+IwCor+ay7Qn4aW7p8Nm'
ICO_B64+='Cbxcn646iwdXLENzs2dTLkuSHUpSUsD5oWcOhV1u1J8oASkK4nqZwwen4XaAUBFnUbFiygxk2pMC'
ICO_B64+='lmloasKc/MWorPV0PpU4G9T0VJ15oSMsMzSXC0TmyW/T9AG6yvMT7sLg7F7+A7bAzPjl+lUoLvkG'
ICO_B64+='ACAsFqiZ6Z7Houet1hMWngdPzKbJb8OHgaHgkR/eigmDvqdLZtGO17H70IcAACIBa2YGSCj68yGY'
ICO_B64+='8K2HCfBpAqLT2DGm/7WYf8toXTJvfvgBlhf9zXutZqSCrJag8kC/DLf8mSO/fV3ERB0DsrKx6M6p'
ICO_B64+='IB17Xx0+8TUeW1fgTa+amgwRnxB0+vXKsQZAM09+R+2CEEeiHQXT7kO8ag1YpqLmHOa89CIaW0zO'
ICO_B64+='ij0BlpTY3ujU8AUhwaAqClbcMwM5yYG7NG5yOjF7+SKUVp8FAAirFaojtcvp1tuZ81T9mmny2/gF'
ICO_B64+='IUHwhwl3Y3jvq3XJPLFhNT756jgAgBQFakYGGNTlzpjefGMGyERLDKKuBsgdeQumDNU3w5f/9x14'
ICO_B64+='4+ABzwUR1AwHoFBI0uzSXDhSdhoAwM7Od3gvq64GWoaAZsnvqDIFj+o3AE+NmaBLZs+nh7Bw+8Wt'
ICO_B64+='j9T0NAhb4P0Gf9Q3NWHCqiVgTUPTt6dCFm+kiJomoG9GJpZPmQGhw5fd0ZMleGRlPtwtZl1Lcg+I'
ICO_B64+='hIQwpZUAVfUfDAAUxTT5HRWfhqXEJ2Dt9Nmw2wLfob6qthb3L/0z6ho9X/eIhHhYUnsgbOkkwJaT'
ICO_B64+='pUPAHPltekugIgRWTL0PV6WlByzjdLuRm78Y356pAACQqsKa7jBtGo3E9DXA78dPxsjv9NUl85tX'
ICO_B64+='1+L9o8UAABIKrJmOlp0RzJlGIzG1IWjmiJGYOWKkLpl1e3Zj0973Wq48PX7SMT0ca5h2NvAHffoi'
ICO_B64+='b7y+hR37iz/D7za94u1gqY4UkM1qurSZCVPWAFelObDy3p/CIgJX76uyUszNXwx3yxpuS5Idit18'
ICO_B64+='n52bDdN1Au22OKydkYuU+ISAZWoa6jFr8Z9QU1cPABBxNlhSU0yTJjNjqk6gIMJL02ahX2bgwym3'
ICO_B64+='puGh/KU4XuoxwpDFAmtGGsyQnmjAVDXA0+Mm4dZrBuqSWbD5Vfzz8KcAWpZyZ6QDJCKWngSrFaum'
ICO_B64+='zw4o7Jm6WjyxfXOYNdKHaWqAKcNGIPemUbpkXtv3D6x+q8hzQQQ1PRWkKohkWixC4OZ+AwIKe+pc'
ICO_B64+='FYzO50sxhSl4+JV98MfJ03TJfHDsCJ7csNqbnWpKMiguLuLp0HM/dmtoLq8EFAWqIzV8SunA8AFy'
ICO_B64+='Tkoq1sx8AKpONyw5aQ68/exCAJ6qPxxuXHIL1+FkdVXoImSGu7ERpBie7V4M9Q8Qr1qxflYuHHb9'
ICO_B64+='+1VemZEZBo3aYlMs/vMlmAUBrX4HTIChdoAB2TkYqGMpd6RxVp5Fc1kF2OU2WpWwYayHEJO8BR3B'
ICO_B64+='zU5oTc0eBwHc0buitwaAqbyOmNISKIkcxs4FmOQt6JCWN5U7eWN155tvnCZA1gAxjrGWQHO8BP7p'
ICO_B64+='7FOuYNJgxk/DTKORqeBLjo7C6I0zGLnw4F1h2fvJnxmmkdbcDGf5GaNu7xdrzyyQ6sd4o2loOlUa'
ICO_B64+='UHykWGDVtX4w9JT8ZQUBRncCfe5tlk5Re3TWCfQJpCMN5kmvKWySwmqFrbd5DUIBIURUpkG6io1x'
ICO_B64+='5DAwxjHVghBJ5JHDwBjHFAtCJMYha4AYR/YBYhzfUUDn3g0k3Qnvs/a1A9QBMMdKRUm48W6FJtr7'
ICO_B64+='p6SbQxefta+v4BIwrjRGI0lEYZS0ngqffx4zRBmJEXifte+eQUegw+OmJJrho61n3gIgSDmgdeft'
ICO_B64+='sSReBLDf59zDyZTsQwCdN0YlSaRgoOZk2flDrdcXv6fat0+z3zB0OIBBRigmiRDMRXUbN21pvWw7'
ICO_B64+='HUy0KeIKSSIKQRT6XrdZEZTqOL+rujKpCkBaRLWSRIqzKennd5/2+UebGuDzBduawbQywkpJIgav'
ICO_B64+='/HzBtjbbs16+IsilLAWj4bIV0fKI9qMBTnUZLuGyj+rrDh1qSBox1A7gR5f+JoliCItKV61789J/'
ICO_B64+='t7sqWIt3PU/1lpkAeoddMUkk+JYTXM+390O7bjXqDx52Jt4w5DgB94ZXL0kkYPB95ctf/W97v3Xo'
ICO_B64+='V6X+o/8cS7phiA1MsimIYgh4oWzVKx127DtdFl6aefUzAO80uvcij+AOAnaUZl3123Yfbgt+Z3/S'
ICO_B64+='58xJsqjugwAG+wsrMRWfuZzKTZXr13e6zsPvhyGV69fXslubBKAiZKpJwk0FiCb5e/iAjvnfrNxZ'
ICO_B64+='faDQTsiawOTwZ0TKpLJVG08EEjpg53r1Hx8+Fz9keKEQ2rUA+gerniSMMHa4XerEijUbAq6tdXlX'
ICO_B64+='bPjkk+b6iZO32uurrZCGIpNBL5Tn9HmoYenSJl1Swd4ua+7MSSDKB0tjkaEQSsD88/I1hTuDEQ/a'
ICO_B64+='v2r9x4eP2QcNWQ2LRgCGAwhwzzRJiGgAeBEaaVr5hsJ2jTyBEJJFgNkP3pvucotHicQjAMup5LBC'
ICO_B64+='VczayxZFW1a6+rXKLscWCpVaGXTPPdazyfHjGNpMEG4Ho0co449hagDsIYhCR82F3Z9vazul2xXC'
ICO_B64+='tww4b5Sl58mcYRpwM5MYQIz+APcGkNRyyCajLU54Ps6pBaiECceItaMC2F92xemPsWCvy2gFJRJJ'
ICO_B64+='d+P/aQhh4yUJ/lIAAAAASUVORK5CYIKJUE5HDQoaCgAAAA1JSERSAAABAAAAAQAIBgAAAFxyqGYA'
ICO_B64+='AAAJcEhZcwAADsQAAA7EAZUrDhsAABiNSURBVHic7d15mBTV1Qbw91R198wwG8wMDIKiogaNUUGJ'
ICO_B64+='xqgR0KAI7oCyg6C4EPIZ4xJN/OKniSsqiCzKvi+KiRrRuEAeE3dBxKDEXVFm2JcZmK3rfH+gBqar'
ICO_B64+='Z7pnaunuen8+PI/dd7ru6amqO7dO3boXICIiIiIiIqIgEL8DcML/rlgRWr1rwxGI6rECHANFJ0Ok'
ICO_B64+='A6D5APIAyRNIrormChDyO15KXQrUiUqlQisBrQBQAchuS/UrCNYr8CFM+XeXgoM/vaN79zq/422u'
ICO_B64+='tGwAuj01s2WeZZxtAmcDcrppyFGqiPgdFwWHCGqiln4M6D+jwEsVhvXSyotH7PA7rmSlTQNwwRPT'
ICO_B64+='uwLGYANGNwGOg4jhd0xEP1C1FFhrwVoJWPOe7jvyHb9DSkRKNwB9lsxub5g6whQZCJVj/I6HKGGi'
ICO_B64+='H0ZVF1hRmfls/2Hf+B1OPKnXAKhKnyWzehkh4wZDtRv/0lNaU7UskZVWnTXu2f7Dl0NE/Q5pf6nT'
ICO_B64+='AKhKn2VzLjWAWw2gi9/hEDnNUl1tifz52UuGPpkqDYH/DYCq9Hli9kBT5DYB2M2njKcq66Kw/vxs'
ICO_B64+='32EL/G4IfG0AzlvyWGcTkcmGgZ/5GQeRHyzF61Gtufa5/le951cMvjQAvebNKzDC1XebpjlaANOP'
ICO_B64+='GIhSgQJRS3VKtDp86/LBg3d5Xb/nDUDvpTP7CWSCAbT1um6iVGUBZQod+7d+I5Z6Wa9nDUCv5yZk'
ICO_B64+='mZX5jxiQK72qkyjdRC2dauXv/vXy88ZWe1GfJw1AnydmHiWWPCGC472ojyidqaVr1ES/Z/uO+Njt'
ICO_B64+='ulxvAM5dPGNA2JCpUM13uy6ijCGyu9bS0c9fdsVCN6txdZBN78Uzbw6LzOfJT5Qk1fywyPxei6fd'
ICO_B64+='5GY17vQAVKX3khn3GyI3uLJ9ogCxBA/8re+Im9wYM+B4A9BvyRJzT3TXLDGMwU5vmyiwLGtujlkw'
ICO_B64+='Ymn//lEnN+toA9BvyRKzQncvMyEXOLldIgKi0KfzJP8SJxsB5ybHUJXKRdNnGoZcoEiJYc5EGcUA'
ICO_B64+='LqiM7poJ1WFOXQ44NgrvnGMOfsA0jKud2h4RxRKRE45Yuyr3kyefftGR7TmxkV4LH7vZEPMeJ7ZF'
ICO_B64+='RI2zLL15+cBR9zV3O81uAHoumnZ5GLLAiW0RUcK0Vq0Bfx9w5eLmbKRZJ+0vn5h5VLgu+i7v8xN5'
ICO_B64+='TyG7LBMnvdB/1CdN3UaTBwL1em5Clllbu5QnP5E/BFpgWLq013MTspq6jSbfBbB25jxsACcw30/k'
ICO_B64+='I0Xn6PashwBc25SPN+kSoOe8KX1Nw/T0sUUiii9qRfv9ffDVTyT7uaQbgF7zJhTAzFkP5fP8RKlC'
ICO_B64+='gTKx9nZaPnhsUpOKJH0JEEXkLkOVJz9RamkbReQuAGOT+VBSPYBz5k45Aaa8KxBO40WUYhQaldro'
ICO_B64+='ic8Pu/b9RD+TeA9AVTD/sclQMZn4I0pFYqppTobq6YkOFU74L3mPIw8aYIj8T9ODIyIPHHLo+++s'
ICO_B64+='//ypZz9I5IcTGwegKqYhtzUrLCLyhClyK1QTurxPqAdw9hFtLjFExjQvLCLyggBtOq59c81ny577'
ICO_B64+='qLGfbbwHoCqGmLdBAf7jP/5Lk3+WeVsivYBGewA9jyrtBchvG/s5IkodItLusPfffePzp55t8DmB'
ICO_B64+='RnsAliW/cS4sIvKKqDY6J2eDXYQesye3DxnypUJ5358ozQgkqjW1HV4c+atv4/1Mg+MARHSoKtfu'
ICO_B64+='I0pHCjWjhjEUQNzJehoeCKQYxPn9iNKXYcogNNAAxM0BdJ81/iQBjnUlKiLyhuInPWZMPDFecdwe'
ICO_B64+='gCHmQP7tJ0p/YmIQgFV2ZXEbAEulm3CWP6K0pypnxiuzPcW7zXyopSmRLergtOFE5A8BolIdKn5p'
ICO_B64+='9Oid9ctscwCGFe7Ok58oMyhgaiTa3a7M9hJADT3b3ZCIyEuWWGcB+Ev99217AAo5w/WIiMg7cfIA'
ICO_B64+='sTmAJUvMHpVlexQScT0oIvKEQGteyW3bAvUWFo25BPhF5baOlvLkJ8okCol0q958+ErggIeDYi4B'
ICO_B64+='VKt/7FlUROQZq8aKObdjegBi6dEwOASIKNOo6NEAnt7/vdgGQMxOUDYARJlGFJ3qv2dzF0AP9SIY'
ICO_B64+='IvKWAcSc2zE9AIXm8+8/UUaKWcjXJgmIPG9iISIvqcSe27E5AI1tJYgo/Qk05ty2uwTIQ2JTihNR'
ICO_B64+='OlFpvAeg0Fye/kSZR0VjGoCYHIBAwt6EQ0Resju37XoA3kRDRL6LfRyY5z9RYCS2OCgRZSReAhAF'
ICO_B64+='GHsARAEW2wOw2AMgCgr2AIgCzGZSUPYAiILCJglIREHBcQBEAcYcAFGAxV4CcDowosBgEpAowHgJ'
ICO_B64+='QBRgNpcAfoRBRH5gD4AowDgOgCjA+DQgUYBxIBBRgHEcAFGAMQlIFGBsAIgCzCYHwEsAoqBgD4Ao'
ICO_B64+='wGyeBQieUw/tiOIWuX6HkTZe//IzbN1T6XcY5ADeBQAw/KSf4cT2HfwOI22MXjYfWyor/A6DHMBx'
ICO_B64+='AJQ8BY+TDMGRgOCxnKx95z9/a5mAzwJQ0uoq96Bm1+4fXodyW0BM08eIqKmYBKSk1e7YiepNW354'
ICO_B64+='bbQ/CGYOG4B0xNuARAFmcxfA8iMOfwXwzkdzqFoHHCf1X1P6YA+AKMA4JRglTfXA46T+a0of7AEQ'
ICO_B64+='BRgHAlHzcWBQ2rIZBxC8ZA6P3eTUHwiksAJ53GQCXgIQBRgbAEpaVW213yGQQ2IuAawg9uR4DZCw'
ICO_B64+='uf94Be999vkB71kWIEE8bjIAewCUsNc+Woc7ly70OwxyEBcHpYR8uXkTxkybhLponU0pbwOkKzYA'
ICO_B64+='AO5dsRz5Wdk/vK7Zug1WdY2PESUmOxLBuGFXolVevqv1VFTtxZWTHsaOOJOAiABBPG4yAccBAPio'
ICO_B64+='vOyA11XfliG6t8qnaBIjIpgw6hrXT35LFWOnTcYnG7+1LQ8XFsDIygrkcZMJmANIU2POOx+9TzrZ'
ICO_B64+='9XrufnIxVn7wvm2Z2SIHkeIi12Mg93BOQBuqmtIz3vTq0hXXn3+J6/Usfe1VTH/5edvfhREKI9K6'
ICO_B64+='ZF9Z6v6qqBGcEMRGpKQIGk3N+1pHt22HB6+42vV63v30Y/x+wSzbPwhiGMg6qA3EZAcy3XFOQBsS'
ICO_B64+='CUP8DsJGcW4eJg8cjuxw2NV6vt22FaOnPoLqutiMvwCItCmBhEOOHitzB45EbiTLse0BQGVNNYYs'
ICO_B64+='mO7oNjMNk4BpImKGMOGiAWibX+hqPXtrajBq0sPYsnOnbXm4uBXMnBzHj5OjWpcecCfGCburq3g8'
ICO_B64+='N4J9uDQgEPzx3AvQuf0hrtd1/YypWPf1V7ZlofxchAsLXI+BvBM7FJhJwJRzxSmn4cKfdHa9nnF/'
ICO_B64+='fRLLV71tW2ZkZyFcXJR2x0e6xes1JgFT3JlHdMJvu/d0vZ5n3n4Tjzz3tG2ZhELIKm39/Yif9GEp'
ICO_B64+='qjZs/O9rQ5Ddrq1/8aQg5gBS2BElbTDuwn4Ql1OSa7/8AjfOehxq2ex8Q5BV2hpimGl4bOgBIzrF'
ICO_B64+='MNLwO7iLdwFSVMucFpjcb5DjmfH6Nu/ciVGPPoQ9NfaP+Ga1LoFEwml7XBwYd2qP7/ADk4ApKGSY'
ICO_B64+='mHDJABzS0t1RdjV1dRj16EPYuH2bbXm4qCXM3BauxkD+4sNAKUYg+EPP3ji5w+Gu13XjrMex+vNP'
ICO_B64+='bMtCebkItyxA+h8PWu//0/37OCv2EiA1B8AFxsCup+CyLu6P8X90+TNY9sa/bMuMrCyEi4oz4ljQ'
ICO_B64+='eud/JnwnJ/ESIIWcetgRuK1nb9freXHNKty3bIltmZgmstq0Bow0y/hTkzAJmCIOKyrG+EsHwBR3'
ICO_B64+='2+T132zA2Mcn2d8fF0GktAQIGRl5HHBZ81jsAaSAguxsTO0/DIXZOa7Ws72iAiMeGYeKKvu5DiIl'
ICO_B64+='Rfue7afAYBLQZ6Zh4KGLL8fhxSWu1lNnRXHV5Ifx9ZZNtuWhwgKYeS2QefufScCGMAnos5vO7oUz'
ICO_B64+='Ov7I9XpunTsTr3/4oW2Z2SIHocKWGbnv9/9OAh7f9fESwEd9O3fFiFNOd72emS+9gAX/WGFbZkT2'
ICO_B64+='TeyRks8/k+vYAPik6yGH4c7eF7lez6vrPsAdi+bblolpIFLKjH+Q8S6ADw5u2QqP9h+MkGG6Ws/n'
ICO_B64+='5WUYPXk8ai2bqbxFEGlTAoTMjN7nHArcMJuHgfgLclOLSART+g9FUYtcV+vZvXcPhk+4HzvjTOUd'
ICO_B64+='KWoFIysSgP1dfyRQpn/f5PASwEOGCMZddDmOLj3I1XosVVw9eXzcqbxD+fkw8/NcjYHSg82swH6E'
ICO_B64+='EQy/7t4Tvzz6WNfruWPRXKxYG2cq7+xshFq1CsR+VtgMBQ7A904GewAeueC4zrjujB6u17Po1ZWY'
ICO_B64+='9uLztmVGKIxwG2b86b84EMgDJ7Q/BPde2M/1et76eD1umTMjzlTegkhpMcQQBHcfcyBQfVwYxGVt'
ICO_B64+='Cwox5bJhiJjuzr62YesWjHpkHGpqbdY0FCBcUgKEQim7f59+f/UB051HK/c0u7++t6bmgG2oSsp+'
ICO_B64+='f79wTkAXZYfDmHr5cLTJd3cm3T3V1Rj28H3YsmuXbXmoVUsYOc5Oue20P/xt2QGvq776BrA4bM9t'
ICO_B64+='zAG4RERw74X9cVy7g12va8zUifgwzlTeZn4uQgXuLiBK6Yt3AVxy3Rk9cL4HU3nf8+RiLH83/lTe'
ICO_B64+='6ZrxVzcu13kXIAaTgC4455if4IazznW9nr+88RomPPMU7PaZhEIIty76LuOffvvUzM1x/myVICdA'
ICO_B64+='7TEH4LBj2rbDQ5cOcr2eNZ9/huunT7ZPahmCcJsSiOnuUGM3hYtb+R1CIDAH4KDi3DxMG3gFclxe'
ICO_B64+='vLN8x3YMH38/qmpsMv4AwiXFMCLuxkCZgQ2AQyKhEKZcPhztClu6Wk91bS1GjH8AZXGm8g61KoTZ'
ICO_B64+='wt2ZhShzcGUgB4gI7upzKbp2OMz1un4zfQpWf2Y/lbfZogVCBQXch5QwJgEdMPLUX6Bfl5+6Xs/4'
ICO_B64+='Z57CstdftS0zIhGES1qB+4+SwUuAZup21NH43Tnnu17P86vexn1PLrItE9P8bow/B/lTctgANMOR'
ICO_B64+='rUvxSP8hMFw+8T7c8BV+NXVi3Km8w63TO+NP/mEOoIlatcjFtEEjkZfl7hDbbbt3Y9iD96Ji717b'
ICO_B64+='8nBxEYxIhPuNmoQ9gCYImSYmXjYUhxYVu1pPbTSKkRMewNdbNtvHUVjAxTupWTgnYBPcft6F+HnH'
ICO_B64+='I12v55bZ0/D6+vhTeZstC7i/qFnYA0jS4JN/jiEnn+Z6PY+/8Bzmr3zZtswIhxEucXfpcAoG5gCS'
ICO_B64+='8POOR+GO3pe4Xs/KtWtwx8K5tvtCTAPh1sUAhPuKmo09gAQdVlyCyQOGwzTc/ZV9WrYRoyc+jLpo'
ICO_B64+='NLZQ9g3zlRAf4SBnsAFIQH52NqYNHonCHHeH2O7cU4mh4+7Bzj2VtuXholYwsrl4JzmHIwEbYRoG'
ICO_B64+='Huk/BEe2LnW1HksVoyc+hE/L4kzlXZCXoYt3kp/YA2jEzT37oNuPjnG9ntvnzcLKtWtsy4ycbIRa'
ICO_B64+='ufuQEQUTk4AN6Hviybjq9O6u1zN/5cuY/vfl9km/cAiR4qKM3y+DTznN8YlTa6J1mPfmvxzdZqZh'
ICO_B64+='NimOrocejrsv6u96PW+u/xC3zJoWZypvY9/KvS4nHlPBzT37ID/b2VGVu6uq2AA0gjkAG+1atsLU'
ICO_B64+='QVcg7PL4+q83b8IV4+9HbV1tbKEIwiWtIGET3CfNwd9dQzL/T0uSciNZmD54FIpz3V07r7KqCkMf'
ICO_B64+='vAdb40zlHW5VmPJTeVP646zA+zFEMK7vIBxzUHtX61FVXDNpPNbFm8o7NxdGXl6g94UjVFG3a7/V'
ICO_B64+='kUVg5rm7KnO6YQ5gP9efdS7OPfZ41+u5e+lCvLAqzlTeWVkIFzHj7wRVRe32HT+8FsNgA1APG4Dv'
ICO_B64+='nH98F4ztcY7r9VTX1uLIdu0xYfSYmDIRgZGTkxaLd7795WdY9PYbfodBzcQkIIDj23fAuL4DPakr'
ICO_B64+='KxxG/9PP9KQuty16+3UHt+bWcVdvffAAHt8NCfw4gNKCQkwbMgpZIU6jnbR0OFZ4/jco0HcBIqEQ'
ICO_B64+='Hhs8EqUFhX6HQuSLQOcA2uQXoPMhh/odRlqyqmtQu3X7D6+NrAgTbGko0A0ANZ3W1SFaeeBTi2wA'
ICO_B64+='0o9NDiBAF0lB+q5Oq389rSm69G46xOijQOcAiIKODQBRgLEBIAqwQE8LHqTv6rwDkwD63X+pZ/8Y'
ICO_B64+='JUVj9E+wBwIF6bu6IR0G2aRDjD7iJQBRgLEBIAowNgBEARbwgUB+B5Du6l1gp+Sxs19MHAgUgz0A'
ICO_B64+='ogBjA0AUYIF+GGjD9q3ocNN/Z+bRuihqNpb5GFFwHXv7jQe8rt6wEVDLp2iCI9jjAOrjfeKmc+N3'
ICO_B64+='5/T2xIVtpjlOCXYAtgBN5/Tvzq0Whft3fzZDgYOLh0fzOH36u4H790CBzgHUJyETWYe4uyYAJSar'
ICO_B64+='/UF+hxAIzAEQBRhvAxIFGJOARAHGHgBRgLEBIAowJgGJAow9AKIAYxKQKMDYAyAKsNihwOwAEAUG'
ICO_B64+='ewBEAcYcAFGAsQdAFGAcB0AUYOwBEAWYXQNQ63kUROSFmvpv2CUBdwMo8iAYIvLW7vpv2PUAYn6I'
ICO_B64+='iDJCzLkd2wOwsAviSTBE5K1d9d+I7QEIewBEmUkb7wGoTStBROlPIDHntk0DoF/wCoAo81iqX9R/'
ICO_B64+='zyYHoOshbAKIMo+sr/9OTA5ANfaHiCgTGI03AFaojg0AUQayrGjjDcCmbyq+BFDtSURE5JXq8vKd'
ICO_B64+='X9V/04z5sXXrNP/kEy8GwLWZiDLH+7tnzptS/03bh4EUutL1cIjIMwqssHvftgEwgFfcDYeIvGSK'
ICO_B64+='/Tlt2wDsRdWrAKKuRkREXolWZVuv2hXEveHfbszINwCc4lpIROSVN76dOP1Uu4K4E4KIysvuxUNE'
ICO_B64+='XhGVuJf0NvMB7FMndYsMmLe6ExIReSVq6sJ4ZXF7AOUTZ60F8J4rERGRV1aXT5j+QbzCxuYEnONw'
ICO_B64+='METkJdUGz+G4lwAAUGdFF4bEuB92A4aIKNVFoyEjbvcfaKQHsHnSrDIRPO9sTETkBRE8v2n8tPKG'
ICO_B64+='fqbRacGj0AedC4mIvGJZGNfYzyTy4L+0ve6Kfwlgex+RiFLSaxsfnXE6Glnqp8EcwHcUlvwJos86'
ICO_B64+='ExcRuU3F+hMSWOcr0al/5KBrR6wC0LlZURGRF1ZvnDTzJCTQACS6NJgCemfzYiIib+hdSHCVz2Qm'
ICO_B64+='/5ODrh3xMoDuTYqJiLywYuOkmWchwQYgkRzA91SjGAMDa5L8HBF5o07EvA5JrPGd1ACfinff25zX'
ICO_B64+='tUseBKclHRoRuUvxQNnkGQ0O/Kkv6b/kUSPnTtOqHAiRg5P9LBG5RHVD1MhNOk+XaBLwB5snTapQ'
ICO_B64+='GNck+zkico/CuGbzpEkVyX6uSWP8K9957z+5XU8oFAgHBxH5TfBg+ZRZE5vy0aR7AN8r3rrnFgBv'
ICO_B64+='NfXzROSIt4q2VP6uqR9u1hpgpaOGHC4hczWAwuZsh4iSp4odIuhSNmXWF03dRrMe861c9f6O/J92'
ICO_B64+='/gjQy9DMxoSIkqKADiifOvvN5myk2c/5V7zz3ke5J3XZJoJezd0WESVKx5ZPnTO3uVtxZKKPynff'
ICO_B64+='eyuv6wkmVM50YntE1KD/K5s65z4nNuTYTD8V76xZmXtSl7Yi6OrUNokoxpSyqbNvdGpjTg7p1fLt'
ICO_B64+='ldeVFuW0BHCZg9slon0Wl2/bOwZJDPVtjLNz/a1bp5Udf/RUXna4FOwJEDlGIFPKt+0dhaVLHV2x'
ICO_B64+='y63MvbQdPeyPqnq7S9snCgwB7ih7bM4dcPAv//dcm+234t01K/NPOmErgF7gLUKiplABxpY95kzC'
ICO_B64+='z47rJ2bp6KEXQnU2IBwsRJS4HRAML586569uVuLJX+bSUUMOh4HFAH7qRX1EaU3xlpjmZc0Z4Zco'
ICO_B64+='Txb8qFz1/o5DO3aavTc7lAfOLkwUl0AfLN5RPejzOQu2elOfx0qvHNpHoZMF4HwCRN9RYINAril/'
ICO_B64+='fI6ns297vuRX5ao1/2nxs06PwwqFBDgFzXgikSgD1CnkfqlC//KZc//tdeW+Zufbjh70Y7WMRwF0'
ICO_B64+='8zMOIp+sMBTXbZw290O/AkiF23PSZtSQiw1Df6+KLn4HQ+Q2Eay2LLlr07S5T8GFe/tJxeJn5fVI'
ICO_B64+='61FDegms34MzDVFG0tcVxl2bp81dDp9P/O+lUgPwPWl7xcBuaho3qOJccGlySm9RhSw3reiDZTMW'
ICO_B64+='rESKnPjfS8UG4AdtRg0oFRgDFDIU4OUBpZXVAp2jsBZumrawwSW6/ZTSDcD+Sq8adJxlyeUC9MC+'
ICO_B64+='AUXsGVAqiQJ4W4FXDEMXlT82f63fASUibRqA/RUNGlRg5ujpYkkPGOgOlWMBzfI7LgoSqYbov2Fh'
ICO_B64+='hRr6SnSv/HPb/Pm7/I4qWWnZAMTo188sLczuYKl2MoBOCnQC9DAABYDkA1oAIP+7fxFfY6VUVwNg'
ICO_B64+='975/sgvQ3QB2AfKFAOstYL0hsr58Z9VXTj+aS0RERERERETklv8HCecqTpT0lhYAAAAASUVORK5C'
ICO_B64+='YII='
LOCAL_ICO="$SCRIPT_DIR/drive_letter_changer_z.ico"
"$PYTHON" -c "import base64,sys; open(sys.argv[1],'wb').write(base64.b64decode(sys.argv[2]))" "$LOCAL_ICO" "$ICO_B64"
echo " OK   Icon (local):  $LOCAL_ICO"

# Extract the PNG frames embedded in the .ico and install them into
# the XDG hicolor theme so 'Icon=drivechangerz' resolves at every size
# a desktop consumer (Desktop/Folder View, Kickoff sidebar, etc.) asks
# for. No PyQt6/Qt dependency needed for this -- .ico is just a small
# directory structure (ICONDIR + ICONDIRENTRY records) pointing at
# plain PNG blobs, so plain struct parsing is enough.
ICON_GEN="$SCRIPT_DIR/.icon_extract.py"
cat > "$ICON_GEN" <<'ICOPYEOF'
import os, struct, sys

ico_path, out_root = sys.argv[1], sys.argv[2]
with open(ico_path, "rb") as f:
    data = f.read()

reserved, itype, count = struct.unpack_from("<HHH", data, 0)
if reserved != 0 or itype != 1:
    print("  WARNING: not a valid .ico file", file=sys.stderr)
    sys.exit(1)

for i in range(count):
    entry_off = 6 + 16 * i
    w, h, _colors, _res, _planes, _bitcount, size, offset = struct.unpack_from(
        "<BBBBHHII", data, entry_off
    )
    w = w or 256
    h = h or 256
    blob = data[offset:offset + size]
    if blob[:8] != b"\x89PNG\r\n\x1a\n":
        # Older-style raw BMP/DIB frame instead of PNG -- skip it, the
        # PNG-format frames (which every size in this .ico uses) are
        # the ones the icon theme actually needs.
        continue
    size_dir = os.path.join(out_root, f"{w}x{h}", "apps")
    os.makedirs(size_dir, exist_ok=True)
    dest = os.path.join(size_dir, "drivechangerz.png")
    with open(dest, "wb") as out:
        out.write(blob)
    print(f"  OK   {w}x{h} -> {dest}")
ICOPYEOF

if "$PYTHON" "$ICON_GEN" "$LOCAL_ICO" "$HOME/.local/share/icons/hicolor" 2>&1; then
    echo " OK   Icon PNGs extracted into hicolor theme."
else
    echo " WARNING: Icon extraction failed - the app will still run, just without a themed icon." >&2
fi
rm -f "$ICON_GEN"

# Refresh GTK icon cache so 'drivechangerz' resolves immediately.
# Suppress all output and errors — this is a best-effort hint to the DE.
for _cache_cmd in gtk-update-icon-cache gtk4-update-icon-cache; do
    if command -v "$_cache_cmd" &>/dev/null; then
        "$_cache_cmd" -f -t "$HOME/.local/share/icons/hicolor" &>/dev/null || true
        break
    fi
done


# Clear KDE's own icon lookup cache (KIconLoader). This is the cache
# that most often goes stale after swapping out a custom app icon —
# gtk-update-icon-cache and kbuildsycoca alone don't always touch it,
# which is why a re-run of this script can otherwise keep showing the
# old icon render even after the files on disk are correct.
rm -f "$HOME/.cache/icon-cache.kcache" 2>/dev/null || true

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

# ── Restart Plasma shell ──────────────────────────────────────────
# The icon-cache.kcache removal above only takes effect for processes
# started after it — plasmashell itself keeps the stale render in
# memory until it restarts. This makes the fix visible immediately on
# the Desktop and in the Kickoff sidebar without a manual logout.
if pgrep -x plasmashell &>/dev/null; then
    echo " Restarting Plasma shell to apply the new icon (brief flash is normal)..."
    if command -v kquitapp6 &>/dev/null; then
        kquitapp6 plasmashell &>/dev/null || true
    elif command -v kquitapp5 &>/dev/null; then
        kquitapp5 plasmashell &>/dev/null || true
    else
        pkill -x plasmashell &>/dev/null || true
    fi
    sleep 1
    if command -v kstart6 &>/dev/null; then
        nohup kstart6 plasmashell &>/dev/null & disown
    elif command -v kstart5 &>/dev/null; then
        nohup kstart5 plasmashell &>/dev/null & disown
    else
        nohup plasmashell --replace &>/dev/null & disown
    fi
    echo " OK   Plasma shell restarted."
fi

echo
echo " =========================================="
echo "  Setup complete!"
echo " =========================================="
echo
echo "  Script:    $PY_SCRIPT"
echo "  Icon:      $LOCAL_ICO"
echo "  XDG icon:  PNGs extracted into $HOME/.local/share/icons/hicolor/*/apps/drivechangerz.png"
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
