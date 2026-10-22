# Configuration PC

Un petit ensemble de scripts pour afficher les composants et les informations
principales de votre ordinateur, qu’il s’agisse d’un PC fixe ou d’un ordinateur
portable.

Les scripts sont en lecture seule : ils recueillent les informations du
matériel et les enregistrent dans un fichier texte. Selon le système, le
rapport est également copié dans le presse-papiers.

## Informations relevées

- Processeur : modèle, nombre de cœurs et de threads
- Carte graphique : modèle, marque, mémoire vidéo et pilote quand ces données
  sont disponibles
- Mémoire vive : capacité totale et, selon le système, détails des barrettes
- Carte mère et BIOS (sur Windows et Linux)
- Alimentation : non affichée, car le système ne permet généralement pas d’y
  accéder pour en lire les informations
- Stockage : constructeur ou modèle du disque et capacité totale
- Système d’exploitation et modèle de l’ordinateur

Les informations disponibles dépendent du système et du matériel. Certains
composants, en particulier sur les ordinateurs portables, peuvent ne pas être
identifiés en détail. L’alimentation n’est pas affichée, car ses informations
ne sont généralement pas accessibles au système.

## Choisir le script

| Système | Script | Langue du rapport |
| --- | --- | --- |
| Linux | `FR_LNX_Configuration_Materiel_ordinateur.sh` | Français |
| macOS | `FR_MAC_Configuration_Materiel_Ordinateur.sh` | Français |
| Windows | `FR_WIN_Configuration_Materiel_Ordinateur.bat` | Français |
| Linux | `EN_LNX_Computer_Hardware_Configuration.sh` | Anglais |
| macOS | `EN_MAC_Computer_Hardware_Configuration.sh` | Anglais |
| Windows | `EN_WIN_Computer_Hardware_Configuration.bat` | Anglais |

## Utilisation

### Linux

Depuis un terminal, placez-vous dans le dossier du projet et lancez :

```bash
bash FR_LNX_Configuration_Materiel_ordinateur.sh
```

Le rapport est enregistré dans le dossier courant sous `config_pc.txt`. Pour obtenir les détails
des barrettes de RAM (marque, vitesse et référence), le script peut demander
votre mot de passe afin d’exécuter `dmidecode` avec les droits administrateur.
Vous pouvez refuser : le reste du rapport sera tout de même généré.

Si un outil de presse-papiers compatible est installé (`wl-copy`, `xclip` ou
`xsel`), le rapport est aussi copié dans le presse-papiers.

### macOS

Double-cliquez sur `FR_MAC_Configuration_Materiel_Ordinateur.sh`, ou lancez-le
depuis le Terminal :

```bash
bash FR_MAC_Configuration_Materiel_Ordinateur.sh
```

Le rapport est enregistré dans le dossier courant sous `config_pc.txt` et copié dans le
presse-papiers. Appuyez sur Entrée à la fin pour fermer le script lancé depuis
le Terminal.

Exemple de résultat sur macOS :

```text
===== CONFIG MAC =====

MODELE : MacBook Pro (Mac17,9)
PROCESSEUR : Apple M5 Pro
Coeurs / threads : 18 / 18

RAM TOTALE : 24 Go

CARTE GRAPHIQUE :
  - Apple M5 Pro
    Coeurs GPU : 20

STOCKAGE :
  - APPLE SSD AP1024Z (1.0 TB)

SYSTEME : macOS 27.0.1 (build 26A434)

===== FIN =====
```

### Windows

Double-cliquez sur le fichier `.bat` correspondant à la langue souhaitée.
Le rapport s’affiche dans la fenêtre, est copié dans le presse-papiers et est
enregistré dans le dossier courant :

- Français : `config_pc.txt`
- Anglais : `pc_config.txt`

Appuyez sur Entrée à la fin pour fermer la fenêtre.

Exemple de sortie Windows avec le script en français :

```text
===== CONFIG PC =====

PROCESSEUR  : Intel(R) Core(TM) i5-10600K CPU @ 4.10GHz
Coeurs / threads : 6 / 12

CARTE GRAPHIQUE : NVIDIA GeForce RTX 2060 (6 Go)
Marque : ASUS
Driver : 32.0.16.1656

RAM TOTALE  : 16 Go
  - 8 Go, 2133 MHz, Corsair, CMK16GX4M2A2666C16
  - 8 Go, 2133 MHz, Corsair, CMK16GX4M2A2666C16

CARTE MERE  : Micro-Star International Co., Ltd. Z490-A PRO (MS-7C75)
BIOS        : 2.00 (American Megatrends Inc.)

STOCKAGE :
  - LDLC F8+M.2 240 (224 Go)
  - Samsung SSD 990 PRO with Heatsink 2TB (1863 Go)

SYSTEME     : Microsoft Windows 11 Famille (build 26200)
Modele PC   : Micro-Star International Co., Ltd. MS-7C75

===== FIN =====
```

## Dépendances Linux facultatives

Le script utilise les outils système habituels pour lire les informations.
Certaines commandes apportent des détails supplémentaires :

- `lspci` (paquet `pciutils`) pour identifier la carte graphique ;
- `dmidecode` pour les informations détaillées sur les barrettes de RAM ;
- `nvidia-smi` pour les informations de mémoire vidéo des cartes NVIDIA ;
- `wl-copy`, `xclip` ou `xsel` pour copier le rapport dans le presse-papiers.

Si un outil facultatif est absent ou si le matériel ne fournit pas une
information, le rapport peut afficher une valeur inconnue ou omettre le
détail correspondant.

---

# PC Configuration

A small collection of scripts to display the main components and hardware
information of your computer, whether it is a desktop PC or a laptop.

The scripts are read-only: they collect hardware information and save it to a
text file. Depending on the operating system, the report is also copied to the
clipboard.

## Information collected

- Processor: model, number of cores and threads
- Graphics card: model, manufacturer, video memory and driver when available
- RAM: total capacity and, depending on the operating system, module details
- Motherboard and BIOS (on Windows and Linux)
- Power supply: not displayed, because its information is generally not
  accessible to the operating system
- Storage: drive manufacturer or model and total capacity
- Operating system and computer model

The information available depends on the operating system and hardware. Some
components, particularly on laptops, may not be identified in detail. The
power supply is not displayed because its information is generally not
accessible to the operating system.

## Choose a script

| Operating system | Script | Report language |
| --- | --- | --- |
| Linux | `FR_LNX_Configuration_Materiel_ordinateur.sh` | French |
| macOS | `FR_MAC_Configuration_Materiel_Ordinateur.sh` | French |
| Windows | `FR_WIN_Configuration_Materiel_Ordinateur.bat` | French |
| Linux | `EN_LNX_Computer_Hardware_Configuration.sh` | English |
| macOS | `EN_MAC_Computer_Hardware_Configuration.sh` | English |
| Windows | `EN_WIN_Computer_Hardware_Configuration.bat` | English |

## Usage

### Linux

Open a terminal, navigate to the project folder, and run:

```bash
bash EN_LNX_Computer_Hardware_Configuration.sh
```

The report is saved in the current working directory as `pc_config.txt`. To retrieve RAM module details
(manufacturer, speed and part number), the script may ask for your password to
run `dmidecode` with administrator privileges. You can decline; the rest of
the report will still be generated.

If a compatible clipboard utility is installed (`wl-copy`, `xclip` or
`xsel`), the report is also copied to the clipboard.

### macOS

Double-click `EN_MAC_Computer_Hardware_Configuration.sh`, or run it from
Terminal:

```bash
bash EN_MAC_Computer_Hardware_Configuration.sh
```

The report is saved in the current working directory as `pc_config.txt` and copied to the clipboard. Press
Enter at the end to close the script when it was launched from Terminal.

Example macOS output:

```text
===== MAC CONFIGURATION =====

MODEL : MacBook Pro (Mac17,9)
PROCESSOR : Apple M5 Pro
Cores / threads : 18 / 18

TOTAL RAM : 24 GB

GRAPHICS CARD:
  - Apple M5 Pro
    GPU cores : 20

STORAGE:
  - APPLE SSD AP1024Z (1.0 TB)

SYSTEM : macOS 27.0.1 (build 26A434)

===== END =====
```

### Windows

Double-click the `.bat` file for the language you want. The report is
displayed in the window, copied to the clipboard and saved in the current
working directory:

- French: `config_pc.txt`
- English: `pc_config.txt`

Press Enter at the end to close the window.

Example Windows output:

```text
===== PC CONFIG =====

PROCESSOR   : Intel(R) Core(TM) i5-10600K CPU @ 4.10GHz
Cores / threads : 6 / 12

GRAPHICS CARD : NVIDIA GeForce RTX 2060 (6 GB)
Brand : ASUS
Driver : 32.0.16.1656

TOTAL RAM   : 16 GB
  - 8 GB, 2133 MHz, Corsair, CMK16GX4M2A2666C16
  - 8 GB, 2133 MHz, Corsair, CMK16GX4M2A2666C16

MOTHERBOARD : Micro-Star International Co., Ltd. Z490-A PRO (MS-7C75)
BIOS        : 2.00 (American Megatrends Inc.)

STORAGE :
  - LDLC F8+M.2 240 (224 GB)
  - Samsung SSD 990 PRO with Heatsink 2TB (1863 GB)

SYSTEM      : Microsoft Windows 11 Famille (build 26200)
PC model    : Micro-Star International Co., Ltd. MS-7C75

===== END =====
```

## Optional Linux dependencies

The script uses standard system utilities to read hardware information. Some
commands provide additional details:

- `lspci` (provided by the `pciutils` package) to identify the graphics card;
- `dmidecode` for detailed RAM module information;
- `nvidia-smi` for video memory information on NVIDIA graphics cards;
- `wl-copy`, `xclip` or `xsel` to copy the report to the clipboard.

If an optional utility is missing or the hardware does not provide some
information, the report may show an unknown value or omit that detail.
