# Drive Letter Changer Z

**Retarget drive letters inside Windows `.lnk` shortcuts or mount paths inside Linux symlinks fast.**

**Redirecione letras de unidade em atalhos `.lnk` do Windows ou caminhos de montagem em links simbólicos do Linux de forma rápida.**

Made by / Feito por **Ium101**

---

## What it does / O que faz

Drive Letter Changer Z scans a folder (and optionally its subfolders) for `.lnk` shortcut files and Linux symbolic links, detects which drive letters they point to, and rewrites them to a new letter or mount path of your choice. Useful when you reassign a drive letter, migrate a disk, or move a project between Windows and Linux.

O Drive Letter Changer Z varre uma pasta (e opcionalmente suas subpastas) em busca de arquivos de atalho `.lnk` e links simbólicos do Linux, detecta para quais letras de unidade eles apontam e os reescreve para uma nova letra ou caminho de montagem à sua escolha. Útil ao reatribuir uma letra de unidade, migrar um disco ou mover um projeto entre Windows e Linux.

## Features / Funcionalidades

- GUI (PyQt6) and CLI (`--no-gui`) modes / Modos GUI (PyQt6) e CLI (`--no-gui`)
- Windows: remaps drive letters inside `.lnk` shortcuts / Remapeia letras de unidade em atalhos `.lnk`
- Linux: remaps symlinks and optionally detects `.lnk` files too / Remapeia links simbólicos e detecta arquivos `.lnk` opcionalmente (fluxo multiplataforma)
- Dry-run / preview mode before making any changes / Modo de simulação antes de aplicar alterações
- Bilingual UI — English and Brazilian Portuguese (PT-BR) / Interface bilíngue — Inglês e Português Brasileiro
- Dark and light themes / Temas claro e escuro
- Persistent settings saved per OS (`.ini` file next to the script) / Configurações salvas por sistema operacional (arquivo `.ini` ao lado do script)

## Requirements / Requisitos

- Python 3.10 or newer / Python 3.10 ou superior
- `PyQt6` and `pylnk3` — installed automatically on first run / instalados automaticamente na primeira execução

## Setup / Configuração

**Windows** — run / execute `build.bat`. Creates Desktop and Start Menu shortcuts. / Cria atalhos na Área de Trabalho e no Menu Iniciar.

**Linux** — run / execute `./build.sh`. Creates a Desktop shortcut and an app menu entry under Utilities. / Cria um atalho na Área de Trabalho e uma entrada no menu de aplicativos em Utilitários.

## Quick start / Início rápido

```
# GUI (default / padrão)
python drive_letter_changer_z.py

# CLI
python drive_letter_changer_z.py --no-gui /path/to/scan --map C:D

# Help / Ajuda
python drive_letter_changer_z.py --help
```

## License / Licença

AGPLv3 (GNU Affero General Public License v3)
