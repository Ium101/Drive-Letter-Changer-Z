# Drive Letter Changer Z — User Manual / Manual do Usuário

## Overview / Visão Geral

Drive Letter Changer Z edits `.lnk` shortcut files (Windows) and symbolic links (Linux) so they point to the correct drive letter or mount path after a disk reassignment or migration.

O Drive Letter Changer Z edita arquivos de atalho `.lnk` (Windows) e links simbólicos (Linux) para que apontem para a letra de unidade ou caminho de montagem correto após uma reatribuição ou migração de disco.

---

## Installation / Instalação

### Windows

1. Place `drive_letter_changer_z.py`, `drive_letter_changer_z.ico`, and `build.bat` in the same folder. / Coloque `drive_letter_changer_z.py`, `drive_letter_changer_z.ico` e `build.bat` na mesma pasta.
2. Double-click `build.bat`. / Dê dois cliques em `build.bat`.
3. The script installs `PyQt6` and `pylnk3`, then creates a Desktop shortcut and a Start Menu entry. / O script instala `PyQt6` e `pylnk3`, depois cria um atalho na Área de Trabalho e uma entrada no Menu Iniciar.

### Linux

1. Place `drive_letter_changer_z.py` and `build.sh` in the same folder. / Coloque `drive_letter_changer_z.py` e `build.sh` na mesma pasta.
2. Run `chmod +x build.sh && ./build.sh`. / Execute `chmod +x build.sh && ./build.sh`.
3. The script installs dependencies, generates an SVG icon, and creates a Desktop shortcut and an app menu entry under **Utilities**. / O script instala as dependências, gera um ícone SVG e cria um atalho na Área de Trabalho e uma entrada no menu de aplicativos em **Utilitários**.

---

## Using the GUI / Usando a Interface Gráfica

Launch the app from the Desktop shortcut or by running: / Inicie o aplicativo pelo atalho da Área de Trabalho ou executando:

```
python drive_letter_changer_z.py
```

### Step-by-step / Passo a passo

1. **Select a folder / Selecione uma pasta** — click **Browse Folder…** to choose the directory to scan. Tick **Scan sub-folders** to include nested directories. / Clique em **Procurar Pasta…** para escolher o diretório a ser varrido. Marque **Varrer subpastas** para incluir diretórios aninhados.
2. **Click Scan / Clique em Varrer** — the app finds all `.lnk` shortcuts and/or symlinks and lists the drive letters it detected. / O aplicativo encontra todos os atalhos `.lnk` e/ou links simbólicos e lista as letras de unidade detectadas.
3. **Set the mapping / Defina o mapeamento** — for each detected drive letter, type the new letter (Windows) or new mount path (Linux) you want to remap to. / Para cada letra de unidade detectada, digite a nova letra (Windows) ou novo caminho de montagem (Linux) desejado.
4. *(Optional / Opcional)* **Enable Dry run / Ativar Simulação** — tick this to preview changes without writing anything to disk. The Log tab will show what *would* happen. / Marque esta opção para visualizar as alterações sem gravar nada no disco. A aba Log mostrará o que *aconteceria*.
5. **Click Apply / Clique em Aplicar** — the app rewrites the files and switches to the **Log** tab, showing each file's result colour-coded: green = changed, yellow = skipped, red = error. / O aplicativo reescreve os arquivos e muda para a aba **Log**, mostrando o resultado de cada arquivo com cores: verde = alterado, amarelo = ignorado, vermelho = erro.

### Options / Opções

| Option / Opção | Description / Descrição |
|---|---|
| Scan sub-folders / Varrer subpastas | Recursively scans all nested directories / Varre recursivamente todos os diretórios aninhados |
| Also detect Windows .lnk shortcuts / Detectar atalhos .lnk do Windows | *(Linux only / Somente Linux)* Scans for `.lnk` files in addition to symlinks / Varre arquivos `.lnk` além dos links simbólicos |
| Dry run / Simulação | Preview mode — no files are modified / Modo de visualização — nenhum arquivo é modificado |
| Language toggle (EN / PT-BR) / Alternar idioma | Switches the UI language / Alterna o idioma da interface |
| Theme toggle (Dark / Light) / Alternar tema | Switches the colour theme / Alterna o tema de cores |

### Results table columns / Colunas da tabela de resultados

| Column / Coluna | Description / Descrição |
|---|---|
| File / Arquivo | Filename of the shortcut or symlink / Nome do arquivo do atalho ou link simbólico |
| Path / Caminho | Subfolder path relative to the scanned root / Caminho da subpasta relativo à raiz varrida |
| Type / Tipo | `.lnk shortcut`, `symlink`, or `.lnk → symlink` |
| Old drive / Unidade antiga | The drive letter / mount path currently stored in the file / A letra de unidade/caminho de montagem atualmente armazenado no arquivo |
| New drive / Nova unidade | The drive letter / mount path that will be (or was) written / A letra de unidade/caminho de montagem que será (ou foi) gravado |
| Status | `created`, `skipped`, or `error` / `criado`, `ignorado` ou `erro` |

---

## Using the CLI / Usando a Linha de Comando

```
python drive_letter_changer_z.py --no-gui [DIRECTORY] [OPTIONS]
```

### Arguments / Argumentos

| Argument / Argumento | Description / Descrição |
|---|---|
| `DIRECTORY` | Folder to scan (default: current directory) / Pasta a varrer (padrão: diretório atual) |
| `--map OLD:NEW` / `-m OLD:NEW` | Drive letter remapping, e.g. `--map C:D`. Repeatable for multiple letters. / Remapeamento de letra de unidade, ex.: `--map C:D`. Repetível para múltiplas letras. |
| `--dry-run` / `-n` | Preview only — no files are modified / Somente visualização — nenhum arquivo é modificado |
| `--no-recurse` | Scan top-level folder only / Varre apenas a pasta raiz |
| `--detect-other-os` | *(Linux only / Somente Linux)* Also detect `.lnk` shortcuts / Detecta também atalhos `.lnk` |
| `--lang en\|pt` | Output language (default: `en`) / Idioma de saída (padrão: `en`) |

### Examples / Exemplos

```bash
# Remap C → D in all shortcuts under /home/user/links
# Remapear C → D em todos os atalhos em /home/user/links
python drive_letter_changer_z.py --no-gui /home/user/links --map C:D

# Multiple remappings, dry run first
# Múltiplos remapeamentos, simulação primeiro
python drive_letter_changer_z.py --no-gui ./shortcuts --map C:D --map E:F --dry-run

# Windows, top-level only / Somente pasta raiz
python drive_letter_changer_z.py --no-gui C:\Links --map Z:D --no-recurse
```

---

## Settings file / Arquivo de configurações

A `.ini` file is created automatically next to the script on first run: / Um arquivo `.ini` é criado automaticamente ao lado do script na primeira execução:

- **Windows:** `drive_changer_z_config_windows.ini`
- **Linux:** `drive_changer_z_config_linux.ini`

It remembers the last folder, language, theme, and any drive mappings you entered. Delete it to reset to defaults. / Ele armazena a última pasta, idioma, tema e quaisquer mapeamentos de unidade inseridos. Exclua-o para restaurar os padrões.

---

## Troubleshooting / Solução de Problemas

**"pylnk3 could not be installed" / "pylnk3 não pôde ser instalado"** — run `pip install pylnk3` manually, or `pip install pylnk3 --break-system-packages` on system-managed Python installs. / Execute `pip install pylnk3` manualmente, ou `pip install pylnk3 --break-system-packages` em instalações Python gerenciadas pelo sistema.

**GUI unavailable / Interface gráfica indisponível** — the app falls back to CLI automatically if PyQt6 cannot be loaded. Install it with `pip install PyQt6`. / O aplicativo usa a CLI automaticamente se o PyQt6 não puder ser carregado. Instale-o com `pip install PyQt6`.

**Shortcut has no icon (Windows) / Atalho sem ícone (Windows)** — `drive_letter_changer_z.ico` must be in the same folder as the `.py`. Run `build.bat` again to restore it. / `drive_letter_changer_z.ico` deve estar na mesma pasta que o `.py`. Execute `build.bat` novamente para restaurá-lo.

**Desktop shortcut won't launch (Linux) / Atalho da Área de Trabalho não abre (Linux)** — right-click the `.desktop` file and choose *Allow Launching* (GNOME) or mark it trusted (KDE). The setup script attempts this automatically but some desktop environments require a manual step. / Clique com o botão direito no arquivo `.desktop` e escolha *Permitir Execução* (GNOME) ou marque-o como confiável (KDE). O script de configuração tenta isso automaticamente, mas alguns ambientes de desktop exigem uma etapa manual.
