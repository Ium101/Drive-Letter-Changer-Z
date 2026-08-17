@echo off
:: ─────────────────────────────────────────────────────────────────
::  build.bat  —  Drive Letter Changer Z setup
::               Generates icon, creates Desktop and Start Menu shortcuts
::  Run:    build.bat
::  Output: drive_letter_changer_z.ico   (icon, lives next to the .py)
::          Desktop shortcut             → runs drive_letter_changer_z.py
::          Start Menu shortcut          → runs drive_letter_changer_z.py
::
::  Icon:   drive_letter_changer_z.ico is embedded as base64 in this script --
::          the exact same binary file build.sh embeds and extracts PNG frames
::          from on Linux, so both platforms show the identical icon. It's
::          (re)written next to the .py on every run by decoding straight to
::          disk -- no rendering needed.
::
::  NOTE: Dependencies (PyQt6, pylnk3) are installed automatically
::        the first time drive_letter_changer_z.py is run.
:: ─────────────────────────────────────────────────────────────────
setlocal EnableDelayedExpansion
cd /d "%~dp0"

echo.
echo  ==========================================
echo   Drive Letter Changer Z  --  Windows setup
echo   Made by Ium101
echo  ==========================================
echo.

:: ── Find Python 3.10+ ────────────────────────────────────────────
set "PYTHON="
for %%C in (python python3 py) do (
    if not defined PYTHON (
        where %%C >nul 2>&1
        if not errorlevel 1 (
            for /f "delims=" %%V in ('%%C -c "import sys; print(sys.version_info >= (3,10))" 2^>nul') do (
                if "%%V"=="True" set "PYTHON=%%C"
            )
        )
    )
)

:: py launcher fallback — tries 3.13 down to 3.10
if not defined PYTHON (
    where py >nul 2>&1
    if not errorlevel 1 (
        for %%V in (3.13 3.12 3.11 3.10) do (
            if not defined PYTHON (
                py -%%V -c "import sys" >nul 2>&1
                if not errorlevel 1 set "PYTHON=py -%%V"
            )
        )
    )
)

if not defined PYTHON (
    echo  ERROR: Python 3.10+ not found in PATH.
    echo         Download from https://www.python.org/downloads/
    echo         Make sure "Add Python to PATH" is ticked during install.
    pause
    exit /b 1
)

for /f "delims=" %%V in ('!PYTHON! -c "import sys; print(str(sys.version_info.major)+chr(46)+str(sys.version_info.minor))" 2^>nul') do set "PYVER=%%V"
echo  Found: !PYTHON!  (Python !PYVER!)

:: ── Find pythonw.exe (runs .py without a console window) ─────────
set "PYTHONW="
for /f "delims=" %%P in ('!PYTHON! -c "import sys,os; p=os.path.join(os.path.dirname(sys.executable),\"pythonw.exe\"); print(p if os.path.isfile(p) else \"\")" 2^>nul') do set "PYTHONW=%%P"
if not defined PYTHONW (
    :: Not found via sys.executable — try PATH
    where pythonw.exe >nul 2>&1 && set "PYTHONW=pythonw.exe"
)
if not defined PYTHONW (
    echo  WARNING: pythonw.exe not found - shortcuts will open a console window.
    set "PYTHONW=!PYTHON!"
)
echo  Found: !PYTHONW!

:: ── Install / upgrade dependencies ───────────────────────────────
echo  Checking dependencies...
!PYTHON! -m pip install --quiet --upgrade pip
!PYTHON! -m pip install --quiet --upgrade pylnk3 PyQt6
if errorlevel 1 (
    echo  ERROR: pip install failed.  Check your internet connection.
    pause
    exit /b 1
)
echo  OK    Dependencies ready.

:: ── Script location ──────────────────────────────────────────────
set "SCRIPT_DIR=%~dp0"
if "!SCRIPT_DIR:~-1!"=="\" set "SCRIPT_DIR=!SCRIPT_DIR:~0,-1!"
set "PY_SCRIPT=!SCRIPT_DIR!\drive_letter_changer_z.py"
set "ICO_FILE=!SCRIPT_DIR!\drive_letter_changer_z.ico"

if not exist "!PY_SCRIPT!" (
    echo  ERROR: drive_letter_changer_z.py not found in !SCRIPT_DIR!
    pause
    exit /b 1
)

:: ── Write the canonical icon (shared verbatim with the Linux build) ─
:: drive_letter_changer_z.ico is the single source of truth for the icon --
:: the exact same file build.sh embeds and extracts PNG frames from on
:: Linux. It's just base64-decoded straight to disk here, no rendering
:: step needed since it's already a finished multi-resolution .ico.
echo  Writing icon (.ico)...
set "ICO64=AAABAAcAEBAAAAEAIAAbAgAAdgAAABgYAAABACAAFwMAAJECAAAgIAAAAQAg"
set "ICO64=!ICO64!ADgEAACoBQAAMDAAAAEAIAACBgAA4AkAAEBAAAABACAAuwYAAOIPAACAgAAA"
set "ICO64=!ICO64!AQAgAIwNAACdFgAAAAAAAAEAIADbGAAAKSQAAIlQTkcNChoKAAAADUlIRFIA"
set "ICO64=!ICO64!AAAQAAAAEAgGAAAAH/P/YQAAAAlwSFlzAAAOxAAADsQBlSsOGwAAAc1JREFU"
set "ICO64=!ICO64!OI2dkk1IlFEUhp/7edOvL2WyP4kCZRYtCiIRW2QgLYQKKoqQWgSuAhdtUiEi"
set "ICO64=!ICO64!2rtqYQgSpARREEUtXLTqzxK0iGoCcRU02qZJnIGZuT/fd9roNBENOAfu5p73"
set "ICO64=!ICO64!OeflvVcBXHp+b8tKPh5pCIIehBZqlaIQJ8nbnKyMzvZfLamuiYmoLaXnFeyv"
set "ICO64=!ICO64!Cf5T8vVXkO/WW0M/5FyyQRiAA1HSNKytdT0qUHXwIMIR7X3cDFLXAFAt2ppy"
set "ICO64=!ICO64!hQ71Jm709kHyZ2Bm6TsPFzP/NRGUnRPjLMZZStbwZTnL5+UsThKOH+zErvXS"
set "ICO64=!ICO64!qVZSDZp1rXGWsnMSOGPFGIsxlkKxyJ35dzxbyNDdnubJ3CyTn95jjOXW6X5O"
set "ICO64=!ICO64!dOxjXWuMxRkr2lor1Rk0ac342Qss5X5ybfoxfu3+8oNJcoU8ztrqDCQQ7xEf"
set "ICO64=!ICO64!V87oyXO0b9/JzaeP2BZGtOpGxMccatvD7s3Nf2nFe3SSxBUD6R27ONN1GIDp"
set "ICO64=!ICO64!oesAzC0ucP7uOIPH+rj/+gUffmSrDIDaOzz4EqG3vlfklRYb56nvHwGs6jj2"
set "ICO64=!ICO64!bxTqVD20IDNaNxZu+1J0EejcIP8xLKsxBdAxMBAWtb+CcFQpUjW3CqsoZiKv"
set "ICO64=!ICO64!x75NTZV/Azca6noHQgquAAAAAElFTkSuQmCCiVBORw0KGgoAAAANSUhEUgAA"
set "ICO64=!ICO64!ABgAAAAYCAYAAADgdz34AAAACXBIWXMAAA7EAAAOxAGVKw4bAAACyUlEQVRI"
set "ICO64=!ICO64!ibWTTWiVRxSGn/PN3Ou9l/xoMZFQA1JosKEkBV3YRYoSpSmtSqGkXRQL9ie6"
set "ICO64=!ICO64!UizBoAsbSLoRggE1SWtLlS6kiFHpptA2ZCE0LQqR0hYXoqVUYyJq/U2+mTku"
set "ICO64=!ICO64!khjvzUc13OSF2cw75z3nvOeM8ATePn7kZW/s6xJF9QgZ5gLloYYwbLz7of+9"
set "ICO64=!ICO64!j36fvhaAT/r6Uv8ssZ1GzC4BMyfhWXnwXn3X8ptu7xctLbEFuFIqHcaHVk8o"
set "ICO64=!ICO64!RnsaBmi9UiIBaJPGb3trI+VCsZUXQsEHoc7GcbzBiMyr+BRMCGG9DbGrU4kW"
set "ICO64=!ICO64!QB8UrbPehwziFyQBKlnrvNOFUZ9MYWM3oUK+RdlUiubaV1DnEqOOnhtCMumn"
set "ICO64=!ICO64!qxPUuthDwXqWpzPsWLshOUiVI4M/IabsWRrAOu8CBSaN3rnNxr5uVCcTP5cr"
set "ICO64=!ICO64!4VDz+5RmsnR934/LpBEX01TzEiYoP178g/EoYVGEYN1EzNSHfgwH/HX9GgAp"
set "ICO64=!ICO64!Y/isaTOlmSxnfv2Fw0NniRalITg633qHXDrNmn1t3LNJn1Sx3vv/HXLHG5tZ"
set "ICO64=!ICO64!veIFLly+ROup42g6hfeTs7k0OkLWWCaCw3tJClerXqHQoylsfbWBd1evYeTW"
set "ICO64=!ICO64!TT78qocJY8DPVLqx98DM48Q6BRvUIzqbfO3Flexp2sR4HLO1p5vREM96U7us"
set "ICO64=!ICO64!ikjhz5GrJDWgIli8QzWfrSpfzMHmLZgo4t8bY7Q0NuWNqb3/O8aC48S2neTS"
set "ICO64=!ICO64!i1i1ewdjktCBKFadQgH5fPkSynI5AKorKqmuqMzj958+gbow42xQVBKGrCDV"
set "ICO64=!ICO64!n27/RpUPZrPFQ4SjNjj3AEncgKKhcN/iGU5sbx4g6LBF+Vk1OMDOs74TzIC5"
set "ICO64=!ICO64!89v5GyWr6iNU16LKvJ0Q2q/2fH3SANx9c/HZ3H+lHmhANSpS3GkI7SNVf3/O"
set "ICO64=!ICO64!4OWQN92lH2+piUJYB9SD5ubmiNwHhkMUDYx9eezi9O0jJddp0euUP6oAAAAA"
set "ICO64=!ICO64!SUVORK5CYIKJUE5HDQoaCgAAAA1JSERSAAAAIAAAACAIBgAAAHN6evQAAAAJ"
set "ICO64=!ICO64!cEhZcwAADsQAAA7EAZUrDhsAAAPqSURBVFiFxZZtaJZVGMd/132f59kzdZtN"
set "ICO64=!ICO64!25pZQyJKemHNSZAZhlBott7MCYXahgn6sT4FQiBFVFBayQyxTbIXv6W4DBox"
set "ICO64=!ICO64!VyooSikMsaIyqj06Ibf25PPc17n6sBf34nOvtTb/cOA+51z39f9fL+fctzAS"
set "ICO64=!ICO64!ZvLop001zrnFJlZuIsEom3FAzLyYdEZR1L6/bt1xRGzY/tDJI5/snh86bRZk"
set "ICO64=!ICO64!4URI88GwYxqFaw+sXtMxSsCyj3fWh0HwHpCaDPIrkIy3aFPL6vUfDAp46KMd"
set "ICO64=!ICO64!t4cSnMAonFzyAQ1kLAzuObiq4UyAmZhqk6oWqlemZKgWajbbhJnIg01bFwSS"
set "ICO64=!ICO64!OD4lkY+AqV/gvJdFhl4Lfgy736lqmQw/DFMpoMyp+uDa0INB4DTKTfSu+e8C"
set "ICO64=!ICO64!zJvzZobP3wML51aScolYR3/0XOLshfT4FQjmNKdmMTXYvHQ5FcUlsX4+++4E"
set "ICO64=!ICO64!L7e2gIyvmGKY896jWF6jrp5uEldp0tnFxYPPP507Ry6bRZwbl4AQwXlTM59f"
set "ICO64=!ICO64!wMrGt8l2XRy2tvHhFbxY+yQAR8508O7n+0jOnQOq1N5RRUVxCWqenUfbYwX4"
set "ICO64=!ICO64!QMzlcpHlpwcKU33O+7H01vm8UPsEAD+fT7OhcRuUzkTNQJWVd1dTfVMl2Shi"
set "ICO64=!ICO64!e+sXBKmCvK5FMecjj48pwVDcVnYDb9Q+jSB0ZzI8t/VNul2ISyTRqK+Rzft+"
set "ICO64=!ICO64!ayP3Vy8upiwBgos0F5+BfpROn05j3RqmJZN4MzY1buPsn10kZpWiGg3aNR1u"
set "ICO64=!ICO64!o+XoN0TqUY2QIXsj4cGcN89YCUiEIY2r1jJ35nUAvLJ3D60dp0mWXz8k4j7s"
set "ICO64=!ICO64!P3US7c30RVhQMGp/KEzA4cHGyMGWx56ipnIeAHu/bmP7wQMkK8oxA0a+G4SE"
set "ICO64=!ICO64!M2ZcIYlpcBHB4f1oJ0PQsGgJdQvuBeC3rgt8+NWX1FRVDTtyvbks36c7AWhe"
set "ICO64=!ICO64!t4Hqm+dxOcpR8+rm2MAQwXnvyVeDVCLBS8tqB+dzZs1m3+Yto+xO/foLK955"
set "ICO64=!ICO64!HYKAaYkkRakUBVFIdOkSYdGMUfYDMOvPQL74AxPCYOzvhM/l0MxlgsLUlWwa"
set "ICO64=!ICO64!mPr4EmADGbg6ev7OULH+WbS7Z0wRidmzMO95/K3XyJ2/AIArKYlvQujvgRi4"
set "ICO64=!ICO64!4iJccdGYAgDwniCZoODGimFrsf7Ne+Ua/ZCAqUNJm8SrnCyISdpJ5I9Y+O+u"
set "ICO64=!ICO64!4v9dAHpYAKnY2NAGtniK+Q/9vn3XEgdYBPWh+W+BaVNE3uvV6gELAXqPnbw4"
set "ICO64=!ICO64!veauHzGWY5bAjEkcveAb0jt2t8OI9i97fu0teN0lIg9MRthmdoggrE+/3/zD"
set "ICO64=!ICO64!wNrVzp+Ur3vmTgvlPoQyIJwgr2KkRe1wZ9Oe04y49/8BTb0xQaYo6FEAAAAA"
set "ICO64=!ICO64!SUVORK5CYIKJUE5HDQoaCgAAAA1JSERSAAAAMAAAADAIBgAAAFcC+YcAAAAJ"
set "ICO64=!ICO64!cEhZcwAADsQAAA7EAZUrDhsAAAW0SURBVGiB1ZppbFRVFMf/576lyxS7TTsp"
set "ICO64=!ICO64!iywWgukHZFEBQUpcAtQFcQUShIbNpKZAXMIHPhhEEgJoAhUKaqMxagQBq6BI"
set "ICO64=!ICO64!XBqNEFACaApEgRZoLUuhQGE6M+/e44fpTDttp/MeBTr9JS+Ze+697557zzl3"
set "ICO64=!ICO64!e0OwweQvP8oyBPdn1rPslO8qRNaFgKLq714ovBCzbLSMqds/HyBV0xINWgHA"
set "ICO64=!ICO64!g26tirY5IaF2GYnmmm0FM6s7KtCuA/NLS43aNGOlpokiAAm3XUUbKKCJpSrp"
set "ICO64=!ICO64!3RBYumnBgkDrvIgO5JeVpaW4eAcBE+6sivZgoKLxOk39Zc6chpAs3IH5paXG"
set "ICO64=!ICO64!mbvEHkEiLpUPoVhV9LuqHgtZQg9lVLnECo0xQbHqPu3sMaHKJVYAeANotsCk"
set "ICO64=!ICO64!sg0D2BTHmOPD52NBhKYAtKE/zZxbrQOApcliUj1DeQBgRqLgwCIAi3UAYEkF"
set "ICO64=!ICO64!iuLeddpAUwAspvzS1W4YCTEXjHhE08itK83sh/gP3I5Rej9dKSsTFHVBjmuU"
set "ICO64=!ICO64!9Ln14I+eaQEhCDosCe6hFoCloFuWBda07lblpmApoVsAoHqmCwGALgOKhQMD"
set "ICO64=!ICO64!/DCvGEmG6bihN3d+hd+rTzqu1xlKgnUAkA6m0STDQJJhOG7Md/4CLGmBhHBc"
set "ICO64=!ICO64!NxoEAV0KxXfChRq9Xiilop+gbgbRbAHloAPLvt0G1XA1av79g4dg+rj8CNnW"
set "ICO64=!ICO64!vb9h7/GjcA28G3wLB0sIAV36A8zMtivtOvo3pNfbYV7f9AwsGzEzQvbniX+w"
set "ICO64=!ICO64!9NMyGBnpUIoBBNsqfHAcRvdvOaluOfwH9hyvdNQBVoHmGHAyKgRQclI7sctM"
set "ICO64=!ICO64!QOmseUhPdoVlNZfqMbfkPajkRGiu5Ih2hmR58NDA3HC64sghWD4/yNBhF13T"
set "ICO64=!ICO64!guuAcmCBjhBEWP3U88h1Z4dlN3w+FK5bg0uWHwkZWe3ctK3VlT8AaVkQmv0g"
set "ICO64=!ICO64!t5ihWxaALm6lX390CiYOHhqhXPEH76OytgZmbw8Uq5DnRJRpm1ZKOVqTFGvQ"
set "ICO64=!ICO64!pfJzV2aGZ4aNxLwxD0fIVm/fgp0HDyAhxwNmBkvZrt7hs6eh+wNAc0f+ra2B"
set "ICO64=!ICO64!UhLooGw0GDIYA06CuDXD+/bHyiefi5CV79+LteXbYHrcgKZFfXfZvl+xqf5y"
set "ICO64=!ICO64!xIjr6anOdCGCDgmAnHcgJzUNm6bPhqm3BN2RqpMo3lwCIz0VIiEhPLrRMDLS"
set "ICO64=!ICO64!2guddEARdMACO3SiJMPE5hmFcKf0CsvOX2nAy++ugt80YKS4btqqTiBYzdcq"
set "ICO64=!ICO64!yn5jRIS1z05HXk6fsMwXCGD22lU4d70RpifL1vtGD8zFgEx3OH3oTDWOnfvP"
set "ICO64=!ICO64!gfoABKDDAtiBCy15ZBIm5w2LkO08sA+ezEwU5A4CRTlbVF+6iGN1LQq+NGo0"
set "ICO64=!ICO64!pt43Mpx+e8dWVNaedbRXIouaLWDT3PdkefDqxMfbyaeNHY9pY8d3WvfDih/x"
set "ICO64=!ICO64!1tntoPDZI7JNeeMGOBAAmU52ugTdggWyGQPJphl1hGOhvE1QPh9EUnAV73DM"
set "ICO64=!ICO64!mB3FjkVW0IVsz0IOYqUdzIDq5B3MwTwnbTBAfV8ryieon+3WkdcaYTVcsd9I"
set "ICO64=!ICO64!Kwx3JkRSYjjtr62LWORMTzbItH/WYIiJjqdRkeKCmeKKXTBao61cxMjxdJof"
set "ICO64=!ICO64!E7KcBXHcQaFptO1Oq4dAiqCDVD166KUEMV3UAVnDfOsO2ncSClANAUDvormV"
set "ICO64=!ICO64!INzb3Qo5gypr123OC26nob6Gop7VAVLlQPM3MkGiRCm5CEBip5XiB68m5XoA"
set "ICO64=!ICO64!0ADg2v6DV1NGDTcBjusvlC3QytqNH5cDQDh667JPLQdjN5gR1w/4+7rsU8tD"
set "ICO64=!ICO64!erfcilZUKXNMXrkmaQQzchG6womjh4DdfkO+6F31TfhiKuJa17v/L1/jE+lf"
set "ICO64=!ICO64!9Lp2FwA8AMD5JejtwUtE79TlnF7YWnmgkz97ZC6c1Ue3uEiBnyZ00xRLqCSm"
set "ICO64=!ICO64!ckun9fUbP6npuIgNUl+ZkZ7o1/oQsTt26a7DTBebTFlzZcNnl2OV/R9gHL1/"
set "ICO64=!ICO64!r6xdGQAAAABJRU5ErkJggolQTkcNChoKAAAADUlIRFIAAABAAAAAQAgGAAAA"
set "ICO64=!ICO64!qmlx3gAAAAlwSFlzAAAOxAAADsQBlSsOGwAABm1JREFUeJzlW1tsFFUY/v7Z"
set "ICO64=!ICO64!W5fS0tbCdluQGBWJERAwElBS2SCg3EKBCuVSWpSoRR68vMCDaKIPgKBC5U7B"
set "ICO64=!ICO64!houA0ACWEAkYEEojQQxREUlTgvQChdDSli7snN+H3W27nW136czO0O6X7MP+"
set "ICO64=!ICO64!/+ycb/7z386Zs0CUg8K6ipkmHfz+FYl5ugTTSICdRNQbgD2y9MLGfWa+BVCl"
set "ICO64=!ICO64!gFwCYP+hjOyzIOJQP+zYAMw0+cD2bAmm5QTurxVbPcCgawLy8sMZC3Z0ZIh2"
set "ICO64=!ICO64!DTBpf8FAEthDREMiQ1E3XBTEs4/MyLkcTBnUABN3b5lIJmkXAfGR5aYPGKgF"
set "ICO64=!ICO64!y1lH3nqnuK1OYYAJOwveNJvFIQZM+tDTB8yQGZh8dNbCo63lAQaYsHfrcyRE"
set "ICO64=!ICO64!KTF66UtPJxDuAjyieNaiK36R1KxkJn4o9kCgFzPQLT8CCULQHjBTi018GLtz"
set "ICO64=!ICO64!w3yJaYdus2EgmGj+z3MWFQJ+D2AmkvGZ8VOk00cWn/u9gADAtS1/lGSiM4ZN"
set "ICO64=!ICO64!iQHwCM/IX3KWnDN7v3KGCNkzdS9IZJoOwGsAmcRIEuF1xd0FTDwKALweIOAE"
set "ICO64=!ICO64!oswFmFIAnwEEsyO65h8A2AH4DMBC9Iiy+QeAWKDFA4ylYiC8HsDCaB6GwR8C"
set "ICO64=!ICO64!RvMwDN4yGPUhEG1dUCt4+wAVHjB32Aj065WoCZnCC+fwX+1dTe4VLrwhoCIH"
set "ICO64=!ICO64!pD/1LF5M7asJmYMlp/HQ7YZksWhyv3CgQRXQLnw89Q0Qnocgs36bUd4+4DGp"
set "ICO64=!ICO64!ArJgCCFAOvLxGaDzs3jtzm3EgMJKpCZJwoDUtKC6s5f/wu9lV2Fx9gHpmJRV"
set "ICO64=!ICO64!V4FlxUVw36qBcD8Ife20zKAGuHarGnmb88FWKySLTdeqpEknaE1OCnnNtEFD"
set "ICO64=!ICO64!kTtmrEJe33QfC/O/Rq27CTGpTjBEQFpZ/KoLC14eFfCbuqYmuL5bpYqzH6qr"
set "ICO64=!ICO64!QDgY3rc/Ph0/RSEXzMjbmI9/KytgS0uBIABtuJhNEuwWa4DM45FRX34d9ieD"
set "ICO64=!ICO64!h9OjIOKNUGp8Ar7NyILFpMzsX+zbjZOX/oA1pTfIZA7OIyg1BsuyJrwjuhiy"
set "ICO64=!ICO64!W6xYnzkXT8TGKnT7zpzCpmM/wZKUACnG1i4HbqdJY2ZNeEesDBIIK6fOxECH"
set "ICO64=!ICO64!U6E7f/UKPtmxGVKsHVJczw7Hb98AQhPePg9QfR8FPnSNw7iBLyjkN27XIHft"
set "ICO64=!ICO64!V/BIJtiSkkKO3eB2o+ZeXYAh7jU2Nu9wq4VvQ0RbD5gyaCjeH+1SyBvdbmR/"
set "ICO64=!ICO64!swo1DQ2wOvtAIPRTrD11HGsOH4BcVx+okEgT3qoXQ20xOK0fVkzNVMiZGR9s"
set "ICO64=!ICO64!Woc/r5fDmuIASVLY45rj42COj1MqNOCtqQEccfHYNDsHNrNZoVt5cC+Kz5fC"
set "ICO64=!ICO64!0jsZksUcmbjrBHw5QD0Zm9mMjVk5cMQpjxQcKi3B6qIfYU6Ih2SP0WQ8raCZ"
set "ICO64=!ICO64!B6ycNgtD0p5UyC+Vl2HJpnUw9bB73fgxenig2QDqbrL4tdcxZfAwhfxm7V3M"
set "ICO64=!ICO64!X70CDwBYkxI7Nc6i0WMwp00rXN/kxsR8DVthNS45/vlB+GjsG0F1xy9ewLhh"
set "ICO64=!ICO64!L8HUK86b9ELgn+pK/FZeFiBLtMeif1JygKzufiPcFVWwOh2d5u2HqhCIj7Fj"
set "ICO64=!ICO64!TeZcEAV/r5SV7kJWurIctoftp06i9PLfkGyte//g7TF7PMZXgVirFbFWm2oS"
set "ICO64=!ICO64!foimJoiGBkjWMLbENOqEVIVAJLK5t8fn1oJ2rtNmfHVVIBIZPdyZ1cgDCAD6"
set "ICO64=!ICO64!fZzX6TuxLONBRZVqIn6YesbCnJgQIPPU1kGuuxd4oSTBlqZcaD0Krq/KJ/WN"
set "ICO64=!ICO64!kCTB2jdVFZG2aMvHFB8HU5BW2PgQ6AbwnxEyloWB0Gwt0FXhD4EG+E5MRBHq"
set "ICO64=!ICO64!gRYPqATwjKF09Ecl4DMAMW5wlBmAgAqg5dXYr0RIN5aSvhDg00BzFRBFzLTM"
set "ICO64=!ICO64!SEK6Q6IioOW0OKXk5V6hKAkDBq5W5W8bAIDNLTIsA/MPBvLSD8xL4Wt+Wi/k"
set "ICO64=!ICO64!KeW9BSUARhhCSj+UVq3fPhI+A7TepmEh8xww7oB96u73uSNAWf6HB4L8acrx"
set "ICO64=!ICO64!bo6LWBxDc4LsNvAwSeOrNxScaC0MupfleHueCxLtAxD6xX/XwB0Inlm9pfBE"
set "ICO64=!ICO64!W0W7h8T7LMp+mljsRNfPCaXskbNuFuwqC6YMdUqeUhbOm8HEX6LrlcirxLS0"
set "ICO64=!ICO64!amvhfnSw3A33bwKUnDtvOJGYKhGNZuZUAE4APbVgqgHqAVQSUYVgPs3ERTVb"
set "ICO64=!ICO64!dl1ANK/zw8X/G8iqM/6sBpMAAAAASUVORK5CYIKJUE5HDQoaCgAAAA1JSERS"
set "ICO64=!ICO64!AAAAgAAAAIAIBgAAAMM+YcsAAAAJcEhZcwAADsQAAA7EAZUrDhsAAA0+SURB"
set "ICO64=!ICO64!VHic7Z15dFTVHce/v/vmzWSZkGWykCAqPSCLtCAotdgqHkRkOYgWobJowSBq"
set "ICO64=!ICO64!W6xae6zHNsWqpS2yGYSw6wlYFu0BU1DRlqVFz1HUYiNQRdEAWQgJIQtJZub9"
set "ICO64=!ICO64!+sckwwSSzLzJzLw3mfvJeee8l7m/+373vvvu8rv3/S4gkUhiFwpXxA8WFKil"
set "ICO64=!ICO64!GfEjiWkUQRtIRH0FUQ4DiQASCLCE697RCAMuAA0E1GvMp5n5S4Y4wsR7s89c"
set "ICO64=!ICO64!OLh63jxnOO4b0gIwbtdym1KX8mNF4RkK6GYG7KGMP1YhoM4N3u920ya3/dzr"
set "ICO64=!ICO64!u8fPbwph3F1n9OY1WYk29SkBmg0gORRxSjqkRgNvqG9yLnxv+tzyrkbWpQIw"
set "ICO64=!ICO64!rrCwh8XmfA6guYIorqvKSAJHY24EsJqs7md23vlAbbDxBF0Axm1dP00VYgkB"
set "ICO64=!ICO64!2cHGIek6DJQ6Ne2x3VPnbAlGXn8ByMsTEwf3WSKA+cHcUBIeNOZlRcUnHseC"
set "ICO64=!ICO64!BZoeOV0F4LatBck2VrYJEmP0qSeJBKzxO43CNfXdqfNqApUJuABM3L6hH9wo"
set "ICO64=!ICO64!IvA1wakniQQM+h8UTCyaMvuLQMIHVADGbN/Qz6rx+2B2dE09SUQgOuuCduPb"
set "ICO64=!ICO64!U3O/9BdU+Atw29aCZNXlLpIPP4pgdigaim7bWuB3SK50+mtenrjG0WMHgUaA"
set "ICO64=!ICO64!AXlE0QGkk0bXfTl42Gbs28ftPV7ATw0wduAVLwrQ7canRh7BHIIwdmz/nBfb"
set "ICO64=!ICO64!fbgtdNgHGF24appVKH/tTFgSHTjdrmnvznp4a3u/tVsAJu1Yl9RU5zpGRNLI"
set "ICO64=!ICO64!0w1g5lKb3dK/PYthuzNyDTXOZ4WgbOYOmw5JdJHdUON8FsBjl/5wWQ0wevOa"
set "ICO64=!ICO64!LIW1r8EcHxHVJJGB6IKbRJ9LJ5AuqwGE2/lrQMiH391gjic4fwXgSd9/t6kB"
set "ICO64=!ICO64!xu1abnNWWsuIOCWiykkiAjOdU9Obe/quJ2hTA1woo8mqhVMgm/5uCYFTGivE"
set "ICO64=!ICO64!nQC8I4I2BUAIZYbs+HVvCGImfAqAtwkYlZdnEX0yqyGXcXVvGLXaiYq0vQsW"
set "ICO64=!ICO64!uADfGuDK1BsZLB9+d4eQ5O6d8n0A/wZ8CwBbRsm2PzZQoN6KywqAog1gDtsq"
set "ICO64=!ICO64!cYmJYKH1bz33FgDW0I9IVgGxAEP0az33GQVwL1kDxAYE7tV67i0AGrOd5POP"
set "ICO64=!ICO64!CdhnpHexCWBOkJ3A2IDBia3nvoYglWUJiBXU1hOfYaAhikgM5mITIEtATOIz"
set "ICO64=!ICO64!DJQFIBbxHQYap4XEMHxGAUaqITEK32GgkXpIDEIWgBjH76dhku6NrynYSD0k"
set "ICO64=!ICO64!BiGbgBhHDgNjHMNNwemJdqQlJPoPGGEq62pRdaHBaDXCjuFNwE+GXI/7h99o"
set "ICO64=!ICO64!yL07I//gXmz86H2j1Qg7hncCzdr30FwuuBqbQBYFpHTuRiGakcPADnCeO4+G"
set "ICO64=!ICO64!klNwng/aBV9U4NME6PIuFjLMOgvJYDBrYGbD8iYSGD8XYM7nD7AnT1qP7orP"
set "ICO64=!ICO64!KKAbpzIoWlytdPMSYPiCELM2AS5Na9GMTatjKLg4CjCqmTNh3n5zpgJb/nUA"
set "ICO64=!ICO64!rAEaG5g3EcDHEmhMKovLT2NH8afQmpqhNTeHNO5EWxzuuO56XTK1Fy4g9+Ul"
set "ICO64=!ICO64!qGlo7f0zjMqbSGC4JfCdo8V452gxmquq4awO2MWtX4gIK+f9QpeMW9Mwf+3L"
set "ICO64=!ICO64!OF5aCgAQqgpLkt2UtVSoMNwS2ApZrVCSQmcSfvyOSbh96DBdMgvf2IK9xYc9"
set "ICO64=!ICO64!+ggBa88MgMjwvAknpikASkI8lITQuCYaP+i7eHj0WF0y2w4ewJo9bwHwOE2w"
set "ICO64=!ICO64!ZqSDLBa/+WK32bBr7qMB3aOstgZTXynQpVe46XYbNw3O7oXnxt2lS+aj41/g"
set "ICO64=!ICO64!6U0bvdeqIzXgwkggOBIDc6vQ5Hbp0isS+IwCor+ay7Qn4aW7p8NmCbxcn646"
set "ICO64=!ICO64!iwdXLENzs2dTLkuSHUpSUsD5oWcOhV1u1J8oASkK4nqZwwen4XaAUBFnUbFi"
set "ICO64=!ICO64!ygxk2pMClmloasKc/MWorPV0PpU4G9T0VJ15oSMsMzSXC0TmyW/T9AG6yvMT"
set "ICO64=!ICO64!7sLg7F7+A7bAzPjl+lUoLvkGACAsFqiZ6Z7Houet1hMWngdPzKbJb8OHgaHg"
set "ICO64=!ICO64!kR/eigmDvqdLZtGO17H70IcAACIBa2YGSCj68yGY8K2HCfBpAqLT2DGm/7WY"
set "ICO64=!ICO64!f8toXTJvfvgBlhf9zXutZqSCrJag8kC/DLf8mSO/fV3ERB0DsrKx6M6pIB17"
set "ICO64=!ICO64!Xx0+8TUeW1fgTa+amgwRnxB0+vXKsQZAM09+R+2CEEeiHQXT7kO8ag1YpqLm"
set "ICO64=!ICO64!HOa89CIaW0zOij0BlpTY3ujU8AUhwaAqClbcMwM5yYG7NG5yOjF7+SKUVp8F"
set "ICO64=!ICO64!AAirFaojtcvp1tuZ81T9mmny2/gFIUHwhwl3Y3jvq3XJPLFhNT756jgAgBQF"
set "ICO64=!ICO64!akYGGNTlzpjefGMGyERLDKKuBsgdeQumDNU3w5f/9x144+ABzwUR1AwHoFBI"
set "ICO64=!ICO64!0uzSXDhSdhoAwM7Od3gvq64GWoaAZsnvqDIFj+o3AE+NmaBLZs+nh7Bw+8Wt"
set "ICO64=!ICO64!j9T0NAhb4P0Gf9Q3NWHCqiVgTUPTt6dCFm+kiJomoG9GJpZPmQGhw5fd0ZMl"
set "ICO64=!ICO64!eGRlPtwtZl1Lcg+IhIQwpZUAVfUfDAAUxTT5HRWfhqXEJ2Dt9Nmw2wLfob6q"
set "ICO64=!ICO64!thb3L/0z6ho9X/eIhHhYUnsgbOkkwJaTpUPAHPltekugIgRWTL0PV6WlByzj"
set "ICO64=!ICO64!dLuRm78Y356pAACQqsKa7jBtGo3E9DXA78dPxsjv9NUl85tX1+L9o8UAABIK"
set "ICO64=!ICO64!rJmOlp0RzJlGIzG1IWjmiJGYOWKkLpl1e3Zj0973Wq48PX7SMT0ca5h2NvAH"
set "ICO64=!ICO64!ffoib7y+hR37iz/D7za94u1gqY4UkM1qurSZCVPWAFelObDy3p/CIgJX76uy"
set "ICO64=!ICO64!UszNXwx3yxpuS5Idit18n52bDdN1Au22OKydkYuU+ISAZWoa6jFr8Z9QU1cP"
set "ICO64=!ICO64!ABBxNlhSU0yTJjNjqk6gIMJL02ahX2bgwym3puGh/KU4XuoxwpDFAmtGGsyQ"
set "ICO64=!ICO64!nmjAVDXA0+Mm4dZrBuqSWbD5Vfzz8KcAWpZyZ6QDJCKWngSrFaumzw4o7Jm6"
set "ICO64=!ICO64!WjyxfXOYNdKHaWqAKcNGIPemUbpkXtv3D6x+q8hzQQQ1PRWkKohkWixC4OZ+"
set "ICO64=!ICO64!AwIKe+pcFYzO50sxhSl4+JV98MfJ03TJfHDsCJ7csNqbnWpKMiguLuLp0HM/"
set "ICO64=!ICO64!dmtoLq8EFAWqIzV8SunA8AFyTkoq1sx8AKpONyw5aQ68/exCAJ6qPxxuXHIL"
set "ICO64=!ICO64!1+FkdVXoImSGu7ERpBie7V4M9Q8Qr1qxflYuHHb9+1VemZEZBo3aYlMs/vMl"
set "ICO64=!ICO64!mAUBrX4HTIChdoAB2TkYqGMpd6RxVp5Fc1kF2OU2WpWwYayHEJO8BR3BzU5o"
set "ICO64=!ICO64!Tc0eBwHc0buitwaAqbyOmNISKIkcxs4FmOQt6JCWN5U7eWN155tvnCZA1gAx"
set "ICO64=!ICO64!jrGWQHO8BP7p7FOuYNJgxk/DTKORqeBLjo7C6I0zGLnw4F1h2fvJnxmmkdbc"
set "ICO64=!ICO64!DGf5GaNu7xdrzyyQ6sd4o2loOlUaUHykWGDVtX4w9JT8ZQUBRncCfe5tlk5R"
set "ICO64=!ICO64!e3TWCfQJpCMN5kmvKWySwmqFrbd5DUIBIURUpkG6io1x5DAwxjHVghBJ5JHD"
set "ICO64=!ICO64!wBjHFAtCJMYha4AYR/YBYhzfUUDn3g0k3Qnvs/a1A9QBMMdKRUm48W6FJtr7"
set "ICO64=!ICO64!p6SbQxefta+v4BIwrjRGI0lEYZS0ngqffx4zRBmJEXifte+eQUegw+OmJJrh"
set "ICO64=!ICO64!o61n3gIgSDmgdeftsSReBLDf59zDyZTsQwCdN0YlSaRgoOZk2flDrdcXv6fa"
set "ICO64=!ICO64!t0+z3zB0OIBBRigmiRDMRXUbN21pvWw7HUy0KeIKSSIKQRT6XrdZEZTqOL+r"
set "ICO64=!ICO64!ujKpCkBaRLWSRIqzKennd5/2+UebGuDzBduawbQywkpJIgav/HzBtjbbs16+"
set "ICO64=!ICO64!IsilLAWj4bIV0fKI9qMBTnUZLuGyj+rrDh1qSBox1A7gR5f+JoliCItKV617"
set "ICO64=!ICO64!89J/t7sqWIt3PU/1lpkAeoddMUkk+JYTXM+390O7bjXqDx52Jt4w5DgB94ZX"
set "ICO64=!ICO64!L0kkYPB95ctf/W97v3XoV6X+o/8cS7phiA1MsimIYgh4oWzVKx127DtdFl6a"
set "ICO64=!ICO64!efUzAO80uvcij+AOAnaUZl3123Yfbgt+Z3/S58xJsqjugwAG+wsrMRWfuZzK"
set "ICO64=!ICO64!TZXr13e6zsPvhyGV69fXslubBKAiZKpJwk0FiCb5e/iAjvnfrNxZfaDQTsia"
set "ICO64=!ICO64!wOTwZ0TKpLJVG08EEjpg53r1Hx8+Fz9keKEQ2rUA+gerniSMMHa4XerEijUb"
set "ICO64=!ICO64!Aq6tdXlXbPjkk+b6iZO32uurrZCGIpNBL5Tn9HmoYenSJl1Swd4ua+7MSSDK"
set "ICO64=!ICO64!B0tjkaEQSsD88/I1hTuDEQ/av2r9x4eP2QcNWQ2LRgCGAwhwzzRJiGgAeBEa"
set "ICO64=!ICO64!aVr5hsJ2jTyBEJJFgNkP3pvucotHicQjAMup5LBCVczayxZFW1a6+rXKLscW"
set "ICO64=!ICO64!CpVaGXTPPdazyfHjGNpMEG4Ho0co449hagDsIYhCR82F3Z9vazul2xXCtww4"
set "ICO64=!ICO64!b5Sl58mcYRpwM5MYQIz+APcGkNRyyCajLU54Ps6pBaiECceItaMC2F92xemP"
set "ICO64=!ICO64!sWCvy2gFJRJJd+P/aQhh4yUJ/lIAAAAASUVORK5CYIKJUE5HDQoaCgAAAA1J"
set "ICO64=!ICO64!SERSAAABAAAAAQAIBgAAAFxyqGYAAAAJcEhZcwAADsQAAA7EAZUrDhsAABiN"
set "ICO64=!ICO64!SURBVHic7d15mBTV1Qbw91R198wwG8wMDIKiogaNUUGJxqgR0KAI7oCyg6C4"
set "ICO64=!ICO64!EPIZ4xJN/OKniSsqiCzKvi+KiRrRuEAeE3dBxKDEXVFm2JcZmK3rfH+gBqar"
set "ICO64=!ICO64!Z7pnaunuen8+PI/dd7ru6amqO7dO3boXICIiIiIiIqIgEL8DcML/rlgRWr1r"
set "ICO64=!ICO64!wxGI6rECHANFJ0OkA6D5APIAyRNIrormChDyO15KXQrUiUqlQisBrQBQAchu"
set "ICO64=!ICO64!S/UrCNYr8CFM+XeXgoM/vaN79zq/422utGwAuj01s2WeZZxtAmcDcrppyFGq"
set "ICO64=!ICO64!iPgdFwWHCGqiln4M6D+jwEsVhvXSyotH7PA7rmSlTQNwwRPTuwLGYANGNwGO"
set "ICO64=!ICO64!g4jhd0xEP1C1FFhrwVoJWPOe7jvyHb9DSkRKNwB9lsxub5g6whQZCJVj/I6H"
set "ICO64=!ICO64!KGGiH0ZVF1hRmfls/2Hf+B1OPKnXAKhKnyWzehkh4wZDtRv/0lNaU7UskZVW"
set "ICO64=!ICO64!nTXu2f7Dl0NE/Q5pf6nTAKhKn2VzLjWAWw2gi9/hEDnNUl1tifz52UuGPpkq"
set "ICO64=!ICO64!DYH/DYCq9Hli9kBT5DYB2M2njKcq66Kw/vxs32EL/G4IfG0AzlvyWGcTkcmG"
set "ICO64=!ICO64!gZ/5GQeRHyzF61Gtufa5/le951cMvjQAvebNKzDC1XebpjlaANOPGIhSgQJR"
set "ICO64=!ICO64!S3VKtDp86/LBg3d5Xb/nDUDvpTP7CWSCAbT1um6iVGUBZQod+7d+I5Z6Wa9n"
set "ICO64=!ICO64!DUCv5yZkmZX5jxiQK72qkyjdRC2dauXv/vXy88ZWe1GfJw1AnydmHiWWPCGC"
set "ICO64=!ICO64!472ojyidqaVr1ES/Z/uO+NjtulxvAM5dPGNA2JCpUM13uy6ijCGyu9bS0c9f"
set "ICO64=!ICO64!dsVCN6txdZBN78Uzbw6LzOfJT5Qk1fywyPxei6fd5GY17vQAVKX3khn3GyI3"
set "ICO64=!ICO64!uLJ9ogCxBA/8re+Im9wYM+B4A9BvyRJzT3TXLDGMwU5vmyiwLGtujlkwYmn/"
set "ICO64=!ICO64!/lEnN+toA9BvyRKzQncvMyEXOLldIgKi0KfzJP8SJxsB5ybHUJXKRdNnGoZc"
set "ICO64=!ICO64!oEiJYc5EGcUALqiM7poJ1WFOXQ44NgrvnGMOfsA0jKud2h4RxRKRE45Yuyr3"
set "ICO64=!ICO64!kyefftGR7TmxkV4LH7vZEPMeJ7ZFRI2zLL15+cBR9zV3O81uAHoumnZ5GLLA"
set "ICO64=!ICO64!iW0RUcK0Vq0Bfx9w5eLmbKRZJ+0vn5h5VLgu+i7v8xN5TyG7LBMnvdB/1CdN"
set "ICO64=!ICO64!3UaTBwL1em5Clllbu5QnP5E/BFpgWLq013MTspq6jSbfBbB25jxsACcw30/k"
set "ICO64=!ICO64!I0Xn6PashwBc25SPN+kSoOe8KX1Nw/T0sUUiii9qRfv9ffDVTyT7uaQbgF7z"
set "ICO64=!ICO64!JhTAzFkP5fP8RKlCgTKx9nZaPnhsUpOKJH0JEEXkLkOVJz9RamkbReQuAGOT"
set "ICO64=!ICO64!+VBSPYBz5k45Aaa8KxBO40WUYhQaldroic8Pu/b9RD+TeA9AVTD/sclQMZn4"
set "ICO64=!ICO64!I0pFYqppTobq6YkOFU74L3mPIw8aYIj8T9ODIyIPHHLo+++s//ypZz9I5IcT"
set "ICO64=!ICO64!GwegKqYhtzUrLCLyhClyK1QTurxPqAdw9hFtLjFExjQvLCLyggBtOq59c81n"
set "ICO64=!ICO64!y577qLGfbbwHoCqGmLdBAf7jP/5Lk3+WeVsivYBGewA9jyrtBchvG/s5Ikod"
set "ICO64=!ICO64!ItLusPfffePzp55t8DmBRnsAliW/cS4sIvKKqDY6J2eDXYQesye3DxnypUJ5"
set "ICO64=!ICO64!358ozQgkqjW1HV4c+atv4/1Mg+MARHSoKtfuI0pHCjWjhjEUQNzJehoeCKQY"
set "ICO64=!ICO64!xPn9iNKXYcogNNAAxM0BdJ81/iQBjnUlKiLyhuInPWZMPDFecdwegCHmQP7t"
set "ICO64=!ICO64!J0p/YmIQgFV2ZXEbAEulm3CWP6K0pypnxiuzPcW7zXyopSmRLergtOFE5A8B"
set "ICO64=!ICO64!olIdKn5p9Oid9ctscwCGFe7Ok58oMyhgaiTa3a7M9hJADT3b3ZCIyEuWWGcB"
set "ICO64=!ICO64!+Ev99217AAo5w/WIiMg7cfIAsTmAJUvMHpVlexQScT0oIvKEQGteyW3bAvUW"
set "ICO64=!ICO64!Fo25BPhF5baOlvLkJ8okCol0q958+ErggIeDYi4BVKt/7FlUROQZq8aKObdj"
set "ICO64=!ICO64!egBi6dEwOASIKNOo6NEAnt7/vdgGQMxOUDYARJlGFJ3qv2dzF0AP9SIYIvKW"
set "ICO64=!ICO64!AcSc2zE9AIXm8+8/UUaKWcjXJgmIPG9iISIvqcSe27E5AI1tJYgo/Qk05ty2"
set "ICO64=!ICO64!uwTIQ2JTihNROlFpvAeg0Fye/kSZR0VjGoCYHIBAwt6EQ0Resju37XoA3kRD"
set "ICO64=!ICO64!RL6LfRyY5z9RYCS2OCgRZSReAhAFGHsARAEW2wOw2AMgCgr2AIgCzGZSUPYA"
set "ICO64=!ICO64!iILCJglIREHBcQBEAcYcAFGAxV4CcDowosBgEpAowHgJQBRgNpcAfoRBRH5g"
set "ICO64=!ICO64!D4AowDgOgCjA+DQgUYBxIBBRgHEcAFGAMQlIFGBsAIgCzCYHwEsAoqBgD4Ao"
set "ICO64=!ICO64!wGyeBQieUw/tiOIWuX6HkTZe//IzbN1T6XcY5ADeBQAw/KSf4cT2HfwOI22M"
set "ICO64=!ICO64!XjYfWyor/A6DHMBxAJQ8BY+TDMGRgOCxnKx95z9/a5mAzwJQ0uoq96Bm1+4f"
set "ICO64=!ICO64!XodyW0BM08eIqKmYBKSk1e7YiepNW354bbQ/CGYOG4B0xNuARAFmcxfA8iMO"
set "ICO64=!ICO64!fwXwzkdzqFoHHCf1X1P6YA+AKMA4JRglTfXA46T+a0of7AEQBRgHAlHzcWBQ"
set "ICO64=!ICO64!2rIZBxC8ZA6P3eTUHwiksAJ53GQCXgIQBRgbAEpaVW213yGQQ2IuAawg9uR4"
set "ICO64=!ICO64!DZCwuf94Be999vkB71kWIEE8bjIAewCUsNc+Woc7ly70OwxyEBcHpYR8uXkT"
set "ICO64=!ICO64!xkybhLponU0pbwOkKzYAAO5dsRz5Wdk/vK7Zug1WdY2PESUmOxLBuGFXolVe"
set "ICO64=!ICO64!vqv1VFTtxZWTHsaOOJOAiABBPG4yAccBAPiovOyA11XfliG6t8qnaBIjIpgw"
set "ICO64=!ICO64!6hrXT35LFWOnTcYnG7+1LQ8XFsDIygrkcZMJmANIU2POOx+9TzrZ9XrufnIx"
set "ICO64=!ICO64!Vn7wvm2Z2SIHkeIi12Mg93BOQBuqmtIz3vTq0hXXn3+J6/Usfe1VTH/5edvf"
set "ICO64=!ICO64!hREKI9K6ZF9Z6v6qqBGcEMRGpKQIGk3N+1pHt22HB6+42vV63v30Y/x+wSzb"
set "ICO64=!ICO64!PwhiGMg6qA3EZAcy3XFOQBsSCUP8DsJGcW4eJg8cjuxw2NV6vt22FaOnPoLq"
set "ICO64=!ICO64!utiMvwCItCmBhEOOHitzB45EbiTLse0BQGVNNYYsmO7oNjMNk4BpImKGMOGi"
set "ICO64=!ICO64!AWibX+hqPXtrajBq0sPYsnOnbXm4uBXMnBzHj5OjWpcecCfGCburq3g8N4J9"
set "ICO64=!ICO64!uDQgEPzx3AvQuf0hrtd1/YypWPf1V7ZlofxchAsLXI+BvBM7FJhJwJRzxSmn"
set "ICO64=!ICO64!4cKfdHa9nnF/fRLLV71tW2ZkZyFcXJR2x0e6xes1JgFT3JlHdMJvu/d0vZ5n"
set "ICO64=!ICO64!3n4Tjzz3tG2ZhELIKm39/Yif9GEpqjZs/O9rQ5Ddrq1/8aQg5gBS2BElbTDu"
set "ICO64=!ICO64!wn4Ql1OSa7/8AjfOehxq2ex8Q5BV2hpimGl4bOgBIzrFMNLwO7iLdwFSVMuc"
set "ICO64=!ICO64!Fpjcb5DjmfH6Nu/ciVGPPoQ9NfaP+Ga1LoFEwml7XBwYd2qP7/ADk4ApKGSY"
set "ICO64=!ICO64!mHDJABzS0t1RdjV1dRj16EPYuH2bbXm4qCXM3BauxkD+4sNAKUYg+EPP3ji5"
set "ICO64=!ICO64!w+Gu13XjrMex+vNPbMtCebkItyxA+h8PWu//0/37OCv2EiA1B8AFxsCup+Cy"
set "ICO64=!ICO64!Lu6P8X90+TNY9sa/bMuMrCyEi4oz4ljQeud/JnwnJ/ESIIWcetgRuK1nb9fr"
set "ICO64=!ICO64!eXHNKty3bIltmZgmstq0Bow0y/hTkzAJmCIOKyrG+EsHwBR32+T132zA2Mcn"
set "ICO64=!ICO64!2d8fF0GktAQIGRl5HHBZ81jsAaSAguxsTO0/DIXZOa7Ws72iAiMeGYeKKvu5"
set "ICO64=!ICO64!DiIlRfue7afAYBLQZ6Zh4KGLL8fhxSWu1lNnRXHV5Ifx9ZZNtuWhwgKYeS2Q"
set "ICO64=!ICO64!efufScCGMAnos5vO7oUzOv7I9XpunTsTr3/4oW2Z2SIHocKWGbnv9/9OAh7f"
set "ICO64=!ICO64!9fESwEd9O3fFiFNOd72emS+9gAX/WGFbZkT2TeyRks8/k+vYAPik6yGH4c7e"
set "ICO64=!ICO64!F7lez6vrPsAdi+bblolpIFLKjH+Q8S6ADw5u2QqP9h+MkGG6Ws/n5WUYPXk8"
set "ICO64=!ICO64!ai2bqbxFEGlTAoTMjN7nHArcMJuHgfgLclOLSART+g9FUYtcV+vZvXcPhk+4"
set "ICO64=!ICO64!HzvjTOUdKWoFIysSgP1dfyRQpn/f5PASwEOGCMZddDmOLj3I1XosVVw9eXzc"
set "ICO64=!ICO64!qbxD+fkw8/NcjYHSg82swH6EEQy/7t4Tvzz6WNfruWPRXKxYG2cq7+xshFq1"
set "ICO64=!ICO64!CsR+VtgMBQ7A904GewAeueC4zrjujB6u17Po1ZWY9uLztmVGKIxwG2b86b84"
set "ICO64=!ICO64!EMgDJ7Q/BPde2M/1et76eD1umTMjzlTegkhpMcQQBHcfcyBQfVwYxGVtCwox"
set "ICO64=!ICO64!5bJhiJjuzr62YesWjHpkHGpqbdY0FCBcUgKEQim7f59+f/UB051HK/c0u7++"
set "ICO64=!ICO64!t6bmgG2oSsp+f79wTkAXZYfDmHr5cLTJd3cm3T3V1Rj28H3YsmuXbXmoVUsY"
set "ICO64=!ICO64!Oc5Oue20P/xt2QGvq776BrA4bM9tzAG4RERw74X9cVy7g12va8zUifgwzlTe"
set "ICO64=!ICO64!Zn4uQgXuLiBK6Yt3AVxy3Rk9cL4HU3nf8+RiLH83/lTe6ZrxVzcu13kXIAaT"
set "ICO64=!ICO64!gC4455if4IazznW9nr+88RomPPMU7PaZhEIIty76LuOffvvUzM1x/myVICdA"
set "ICO64=!ICO64!7TEH4LBj2rbDQ5cOcr2eNZ9/huunT7ZPahmCcJsSiOnuUGM3hYtb+R1CIDAH"
set "ICO64=!ICO64!4KDi3DxMG3gFclxevLN8x3YMH38/qmpsMv4AwiXFMCLuxkCZgQ2AQyKhEKZc"
set "ICO64=!ICO64!PhztClu6Wk91bS1GjH8AZXGm8g61KoTZwt2ZhShzcGUgB4gI7upzKbp2OMz1"
set "ICO64=!ICO64!un4zfQpWf2Y/lbfZogVCBQXch5QwJgEdMPLUX6Bfl5+6Xs/4Z57CstdftS0z"
set "ICO64=!ICO64!IhGES1qB+4+SwUuAZup21NH43Tnnu17P86vexn1PLrItE9P8bow/B/lTctgA"
set "ICO64=!ICO64!NMORrUvxSP8hMFw+8T7c8BV+NXVi3Km8w63TO+NP/mEOoIlatcjFtEEjkZfl"
set "ICO64=!ICO64!7hDbbbt3Y9iD96Ji717b8nBxEYxIhPuNmoQ9gCYImSYmXjYUhxYVu1pPbTSK"
set "ICO64=!ICO64!kRMewNdbNtvHUVjAxTupWTgnYBPcft6F+HnHI12v55bZ0/D6+vhTeZstC7i/"
set "ICO64=!ICO64!qFnYA0jS4JN/jiEnn+Z6PY+/8Bzmr3zZtswIhxEucXfpcAoG5gCS8POOR+GO"
set "ICO64=!ICO64!3pe4Xs/KtWtwx8K5tvtCTAPh1sUAhPuKmo09gAQdVlyCyQOGwzTc/ZV9WrYR"
set "ICO64=!ICO64!oyc+jLpoNLZQ9g3zlRAf4SBnsAFIQH52NqYNHonCHHeH2O7cU4mh4+7Bzj2V"
set "ICO64=!ICO64!tuXholYwsrl4JzmHIwEbYRoGHuk/BEe2LnW1HksVoyc+hE/L4kzlXZCXoYt3"
set "ICO64=!ICO64!kp/YA2jEzT37oNuPjnG9ntvnzcLKtWtsy4ycbIRaufuQEQUTk4AN6Hviybjq"
set "ICO64=!ICO64!9O6u1zN/5cuY/vfl9km/cAiR4qKM3y+DTznN8YlTa6J1mPfmvxzdZqZhNimO"
set "ICO64=!ICO64!rocejrsv6u96PW+u/xC3zJoWZypvY9/KvS4nHlPBzT37ID/b2VGVu6uq2AA0"
set "ICO64=!ICO64!gjkAG+1atsLUQVcg7PL4+q83b8IV4+9HbV1tbKEIwiWtIGET3CfNwd9dQzL/"
set "ICO64=!ICO64!T0uSciNZmD54FIpz3V07r7KqCkMfvAdb40zlHW5VmPJTeVP646zA+zFEMK7v"
set "ICO64=!ICO64!IBxzUHtX61FVXDNpPNbFm8o7NxdGXl6g94UjVFG3a7/VkUVg5rm7KnO6YQ5g"
set "ICO64=!ICO64!P9efdS7OPfZ41+u5e+lCvLAqzlTeWVkIFzHj7wRVRe32HT+8FsNgA1APG4Dv"
set "ICO64=!ICO64!nH98F4ztcY7r9VTX1uLIdu0xYfSYmDIRgZGTkxaLd7795WdY9PYbfodBzcQk"
set "ICO64=!ICO64!IIDj23fAuL4DPakrKxxG/9PP9KQuty16+3UHt+bWcVdvffAAHt8NCfw4gNKC"
set "ICO64=!ICO64!QkwbMgpZIU6jnbR0OFZ4/jco0HcBIqEQHhs8EqUFhX6HQuSLQOcA2uQXoPMh"
set "ICO64=!ICO64!h/odRlqyqmtQu3X7D6+NrAgTbGko0A0ANZ3W1SFaeeBTi2wA0o9NDiBAF0lB"
set "ICO64=!ICO64!+q5Oq389rSm69G46xOijQOcAiIKODQBRgLEBIAqwQE8LHqTv6rwDkwD63X+p"
set "ICO64=!ICO64!Z/8YJUVj9E+wBwIF6bu6IR0G2aRDjD7iJQBRgLEBIAowNgBEARbwgUB+B5Du"
set "ICO64=!ICO64!6l1gp+Sxs19MHAgUgz0AogBjA0AUYIF+GGjD9q3ocNN/Z+bRuihqNpb5GFFw"
set "ICO64=!ICO64!HXv7jQe8rt6wEVDLp2iCI9jjAOrjfeKmc+N35/T2xIVtpjlOCXYAtgBN5/Tv"
set "ICO64=!ICO64!zq0Whft3fzZDgYOLh0fzOH36u4H790CBzgHUJyETWYe4uyYAJSar/UF+hxAI"
set "ICO64=!ICO64!zAEQBRhvAxIFGJOARAHGHgBRgLEBIAowJgGJAow9AKIAYxKQKMDYAyAKsNih"
set "ICO64=!ICO64!wOwAEAUGewBEAcYcAFGAsQdAFGAcB0AUYOwBEAWYXQNQ63kUROSFmvpv2CUB"
set "ICO64=!ICO64!dwMo8iAYIvLW7vpv2PUAYn6IiDJCzLkd2wOwsAviSTBE5K1d9d+I7QEIewBE"
set "ICO64=!ICO64!mUkb7wGoTStBROlPIDHntk0DoF/wCoAo81iqX9R/zyYHoOshbAKIMo+sr/9O"
set "ICO64=!ICO64!TA5ANfaHiCgTGI03AFaojg0AUQayrGjjDcCmbyq+BFDtSURE5JXq8vKdX9V/"
set "ICO64=!ICO64!04z5sXXrNP/kEy8GwLWZiDLH+7tnzptS/03bh4EUutL1cIjIMwqssHvftgEw"
set "ICO64=!ICO64!gFfcDYeIvGSK/Tlt2wDsRdWrAKKuRkREXolWZVuv2hXEveHfbszINwCc4lpI"
set "ICO64=!ICO64!ROSVN76dOP1Uu4K4E4KIysvuxUNEXhGVuJf0NvMB7FMndYsMmLe6ExIReSVq"
set "ICO64=!ICO64!6sJ4ZXF7AOUTZ60F8J4rERGRV1aXT5j+QbzCxuYEnONwMETkJdUGz+G4lwAA"
set "ICO64=!ICO64!UGdFF4bEuB92A4aIKNVFoyEjbvcfaKQHsHnSrDIRPO9sTETkBRE8v2n8tPKG"
set "ICO64=!ICO64!fqbRacGj0AedC4mIvGJZGNfYzyTy4L+0ve6Kfwlgex+RiFLSaxsfnXE6Glnq"
set "ICO64=!ICO64!p8EcwHcUlvwJos86ExcRuU3F+hMSWOcr0al/5KBrR6wC0LlZURGRF1ZvnDTz"
set "ICO64=!ICO64!JCTQACS6NJgCemfzYiIib+hdSHCVz2Qm/5ODrh3xMoDuTYqJiLywYuOkmWch"
set "ICO64=!ICO64!wQYgkRzA91SjGAMDa5L8HBF5o07EvA5JrPGd1ACfinff25zXtUseBKclHRoR"
set "ICO64=!ICO64!uUvxQNnkGQ0O/Kkv6b/kUSPnTtOqHAiRg5P9LBG5RHVD1MhNOk+XaBLwB5sn"
set "ICO64=!ICO64!TapQGNck+zkico/CuGbzpEkVyX6uSWP8K9957z+5XU8oFAgHBxH5TfBg+ZRZ"
set "ICO64=!ICO64!E5vy0aR7AN8r3rrnFgBvNfXzROSIt4q2VP6uqR9u1hpgpaOGHC4hczWAwuZs"
set "ICO64=!ICO64!h4iSp4odIuhSNmXWF03dRrMe861c9f6O/J92/gjQy9DMxoSIkqKADiifOvvN"
set "ICO64=!ICO64!5myk2c/5V7zz3ke5J3XZJoJezd0WESVKx5ZPnTO3uVtxZKKPynffeyuv6wkm"
set "ICO64=!ICO64!VM50YntE1KD/K5s65z4nNuTYTD8V76xZmXtSl7Yi6OrUNokoxpSyqbNvdGpj"
set "ICO64=!ICO64!Tg7p1fLtldeVFuW0BHCZg9slon0Wl2/bOwZJDPVtjLNz/a1bp5Udf/RUXna4"
set "ICO64=!ICO64!FOwJEDlGIFPKt+0dhaVLHV2xy63MvbQdPeyPqnq7S9snCgwB7ih7bM4dcPAv"
set "ICO64=!ICO64!//dcm+234t01K/NPOmErgF7gLUKiplABxpY95kzCz47rJ2bp6KEXQnU2IBws"
set "ICO64=!ICO64!RJS4HRAML586569uVuLJX+bSUUMOh4HFAH7qRX1EaU3xlpjmZc0Z4ZcoTxb8"
set "ICO64=!ICO64!qFz1/o5DO3aavTc7lAfOLkwUl0AfLN5RPejzOQu2elOfx0qvHNpHoZMF4HwC"
set "ICO64=!ICO64!RN9RYINAril/fI6ns297vuRX5ao1/2nxs06PwwqFBDgFzXgikSgD1CnkfqlC"
set "ICO64=!ICO64!//KZc//tdeW+Zufbjh70Y7WMRwF08zMOIp+sMBTXbZw290O/AkiF23PSZtSQ"
set "ICO64=!ICO64!iw1Df6+KLn4HQ+Q2Eay2LLlr07S5T8GFe/tJxeJn5fVI61FDegms34MzDVFG"
set "ICO64=!ICO64!0tcVxl2bp81dDp9P/O+lUgPwPWl7xcBuaho3qOJccGlySm9RhSw3reiDZTMW"
set "ICO64=!ICO64!rESKnPjfS8UG4AdtRg0oFRgDFDIU4OUBpZXVAp2jsBZumrawwSW6/ZTSDcD+"
set "ICO64=!ICO64!Sq8adJxlyeUC9MC+AUXsGVAqiQJ4W4FXDEMXlT82f63fASUibRqA/RUNGlRg"
set "ICO64=!ICO64!5ujpYkkPGOgOlWMBzfI7LgoSqYbov2FhhRr6SnSv/HPb/Pm7/I4qWWnZAMTo"
set "ICO64=!ICO64!188sLczuYKl2MoBOCnQC9DAABYDkA1oAIP+7fxFfY6VUVwNg975/sgvQ3QB2"
set "ICO64=!ICO64!AfKFAOstYL0hsr58Z9VXTj+aS0RERERERETklv8HCecqTpT0lhYAAAAASUVO"
set "ICO64=!ICO64!RK5CYII="
!PYTHON! -c "import base64,sys; open(sys.argv[1],'wb').write(base64.b64decode(sys.argv[2]))" "!ICO_FILE!" "!ICO64!"
if errorlevel 1 (
    echo  WARNING: Could not write icon - shortcuts will have no icon.
    set "ICO_FILE="
) else (
    echo  OK    Icon: !ICO_FILE!
)

:: ── Create shortcuts via base64-decoded Python script ─────────────
:: Uses PowerShell single-quoted strings throughout to avoid backslash
:: and double-quote escaping issues with Windows paths.
:: Arguments = path to .py (no extra quoting here; the script adds cmd quotes).
echo  Creating shortcuts...
set "LNK_PY=%TEMP%\dlcz_mklnk.py"

set "LB64=aW1wb3J0IHN5cywgb3MsIHRlbXBmaWxlLCBzdWJwcm9jZXNzCgp0YXJnZXQs"
set "LB64=!LB64!IGFyZ3VtZW50cywgbG5rX3BhdGgsIHdvcmtfZGlyLCBpY29uX3BhdGggPSBz"
set "LB64=!LB64!eXMuYXJndlsxOjZdCgpkZWYgcHNfc3Eocyk6CiAgICAjIEVzY2FwZSBmb3Ig"
set "LB64=!LB64!UG93ZXJTaGVsbCBzaW5nbGUtcXVvdGVkIHN0cmluZzogYXBvc3Ryb3BoZSAt"
set "LB64=!LB64!PiBkb3VibGVkIGFwb3N0cm9waGUKICAgIHJldHVybiBzLnJlcGxhY2UoIici"
set "LB64=!LB64!LCAiJyciKQoKIyBhcmd1bWVudHMgaXMgdGhlIC5weSBzY3JpcHQgcGF0aDsg"
set "LB64=!LB64!YWx3YXlzIHdyYXAgaW4gY21kIGRvdWJsZS1xdW90ZXMKIyBzbyBwYXRocyB3"
set "LB64=!LB64!aXRoIHNwYWNlcyB3b3JrIGNvcnJlY3RseSBhcyB0aGUgc2hvcnRjdXQgQXJn"
set "LB64=!LB64!dW1lbnRzIGZpZWxkLgphcmdzX2NtZCA9ICciJyArIGFyZ3VtZW50cyArICci"
set "LB64=!LB64!JwoKcHNfbGluZXMgPSBbCiAgICAnJHdzID0gTmV3LU9iamVjdCAtQ29tT2Jq"
set "LB64=!LB64!ZWN0IFdTY3JpcHQuU2hlbGwnLAogICAgIiRzID0gJHdzLkNyZWF0ZVNob3J0"
set "LB64=!LB64!Y3V0KCciICsgcHNfc3EobG5rX3BhdGgpICsgIicpIiwKICAgICIkcy5UYXJn"
set "LB64=!LB64!ZXRQYXRoID0gJyIgKyBwc19zcSh0YXJnZXQpICsgIiciLAogICAgIiRzLkFy"
set "LB64=!LB64!Z3VtZW50cyA9ICciICsgcHNfc3EoYXJnc19jbWQpICsgIiciLAogICAgIiRz"
set "LB64=!LB64!LldvcmtpbmdEaXJlY3RvcnkgPSAnIiArIHBzX3NxKHdvcmtfZGlyKSArICIn"
set "LB64=!LB64!IiwKICAgICIkcy5EZXNjcmlwdGlvbiA9ICdSZXRhcmdldCBkcml2ZSBsZXR0"
set "LB64=!LB64!ZXJzIGluIC5sbmsgc2hvcnRjdXRzJyIsCiAgICAiJHMuSWNvbkxvY2F0aW9u"
set "LB64=!LB64!ID0gJyIgKyBwc19zcShpY29uX3BhdGgpICsgIiwwJyIsCiAgICAnJHMuU2F2"
set "LB64=!LB64!ZSgpJywKXQoKZmQsIHRtcCA9IHRlbXBmaWxlLm1rc3RlbXAoc3VmZml4PScu"
set "LB64=!LB64!cHMxJykKdHJ5OgogICAgd2l0aCBvcy5mZG9wZW4oZmQsICd3JywgZW5jb2Rp"
set "LB64=!LB64!bmc9J3V0Zi04JykgYXMgZjoKICAgICAgICBmLndyaXRlKCdcclxuJy5qb2lu"
set "LB64=!LB64!KHBzX2xpbmVzKSkKICAgIHN1YnByb2Nlc3MucnVuKAogICAgICAgIFsncG93"
set "LB64=!LB64!ZXJzaGVsbCcsICctTm9Qcm9maWxlJywgJy1Ob25JbnRlcmFjdGl2ZScsICct"
set "LB64=!LB64!RXhlY3V0aW9uUG9saWN5JywgJ0J5cGFzcycsICctRmlsZScsIHRtcF0sCiAg"
set "LB64=!LB64!ICAgICAgY2hlY2s9VHJ1ZSkKZmluYWxseToKICAgIHRyeTogb3MudW5saW5r"
set "LB64=!LB64!KHRtcCkKICAgIGV4Y2VwdCBFeGNlcHRpb246IHBhc3MK"

!PYTHON! -c "import base64,sys; open(sys.argv[1],'wb').write(base64.b64decode(sys.argv[2]))" "!LNK_PY!" "!LB64!"
if errorlevel 1 (
    echo  ERROR: Could not decode shortcut maker.
    pause
    exit /b 1
)

:: Desktop shortcut
:: Note: PY_SCRIPT is passed WITHOUT extra quotes — the Python script adds them.
set "DESK_LNK=%USERPROFILE%\Desktop\Drive Letter Changer Z.lnk"
!PYTHON! "!LNK_PY!" "!PYTHONW!" "!PY_SCRIPT!" "!DESK_LNK!" "!SCRIPT_DIR!" "!ICO_FILE!"
if exist "!DESK_LNK!" (
    echo  OK    Desktop shortcut created.
) else (
    echo  WARN  Desktop shortcut could not be created ^(check permissions^).
)

:: Start Menu shortcut
set "SM_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs"
set "SM_LNK=!SM_DIR!\Drive Letter Changer Z.lnk"
!PYTHON! "!LNK_PY!" "!PYTHONW!" "!PY_SCRIPT!" "!SM_LNK!" "!SCRIPT_DIR!" "!ICO_FILE!"
if exist "!SM_LNK!" (
    echo  OK    Start Menu shortcut created.
) else (
    echo  WARN  Start Menu shortcut could not be created ^(check permissions^).
)

del /f /q "!LNK_PY!" >nul 2>&1

:: ── Refresh Windows icon cache ─────────────────────────────────────
:: Windows caches shortcut/file icons aggressively (IconCache.db /
:: thumbcache database files under %LOCALAPPDATA%). After regenerating
:: a custom .ico under the same filename, Explorer can keep showing the
:: old cached (or blank) icon until that cache is cleared — the same
:: class of issue as KDE's icon-cache.kcache on the Linux side.
echo  Refreshing Windows icon cache...
if exist "%SystemRoot%\System32\ie4uinit.exe" (
    "%SystemRoot%\System32\ie4uinit.exe" -ClearIconCache >nul 2>&1
)
taskkill /f /im explorer.exe >nul 2>&1
del /f /q /a "%LOCALAPPDATA%\IconCache.db" >nul 2>&1
del /f /q /a "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache_*.db" >nul 2>&1
start "" explorer.exe
echo  OK    Icon cache refreshed (Explorer restarted - brief flash is normal).

echo.
echo  ==========================================
echo   Setup complete!
echo  ==========================================
echo.
echo   Script:     !PY_SCRIPT!
echo   Icon:       !ICO_FILE!
echo   Desktop:    !DESK_LNK!
echo   Start Menu: !SM_LNK!
echo   Settings:   !SCRIPT_DIR!\drive_changer_z_config_windows.ini  (created on first run)
echo.
echo  To run:
echo     Double-click the Desktop shortcut
echo     Or: "!PYTHONW!" "!PY_SCRIPT!"
echo     Or: !PYTHON! "!PY_SCRIPT!" --no-gui [DIR]
echo     Or: !PYTHON! "!PY_SCRIPT!" --help
echo.
pause
endlocal
