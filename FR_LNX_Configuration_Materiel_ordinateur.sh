#!/usr/bin/env bash
# FR_Connaitre_Tes_Pieces_PC.sh
# Affiche et sauvegarde la config du PC. Ne modifie rien.

export LC_ALL=C
export PATH="$PATH:/usr/sbin:/sbin"
SORTIE="$PWD/config_pc.txt"

# ---------- Detail de la RAM (mot de passe demande seulement si accepte)
RAM_DETAIL=""
OK=0
SUDO=""
if command -v dmidecode >/dev/null 2>&1; then
  if [ "$(id -u)" -eq 0 ]; then
    OK=1
  elif sudo -n true 2>/dev/null; then
    SUDO="sudo"; OK=1
  else
    echo "Pour lire le detail de la RAM (marque, vitesse), le script a besoin de ton mot de passe."
    read -r -p "Tu veux continuer avec le mot de passe ? (o/N) " rep
    case "$rep" in o|O|y|Y) SUDO="sudo"; OK=1 ;; esac
  fi
  if [ "$OK" -eq 1 ]; then
    RAM_DETAIL=$($SUDO dmidecode -t memory 2>/dev/null | awk '
      /^Memory Device/ { t=""; v=""; f=""; r="" }
      /^[ \t]+Size:/ { if ($2 ~ /^[0-9]+$/) t=$2" "$3; else t="" }
      /^[ \t]+Speed:/ { v=$2" "$3 }
      /^[ \t]+Manufacturer:/ { sub(/^[ \t]+Manufacturer:[ \t]*/,""); f=$0 }
      /^[ \t]+Part Number:/ { sub(/^[ \t]+Part Number:[ \t]*/,""); r=$0 }
      /^$/ { if (t!="") print t "|" v "|" f "|" r; t="" }
    ')
  fi
fi

marque_ram() {
  case "$1" in
    CM*) echo "Corsair" ;;
    F4-*|F5-*) echo "G.Skill" ;;
    KF*|KVR*|KHX*|HX*) echo "Kingston" ;;
    CT*|BL*) echo "Crucial" ;;
    TF*|TED*|TLZ*|TPD*|TLD*|TXD*) echo "TeamGroup" ;;
    AX*|AD[0-9]*) echo "ADATA" ;;
    PV*|PS*|VP*) echo "Patriot" ;;
    M378*|M471*|M391*) echo "Samsung" ;;
    HMA*|HMT*|HMC*) echo "SK Hynix" ;;
    MT*) echo "Micron" ;;
    *) echo "" ;;
  esac
}

dmi() { cat "/sys/class/dmi/id/$1" 2>/dev/null; }

rapport() {
  cpu=$(lscpu | awk -F: '/^Model name/ {gsub(/^[ \t]+/,"",$2); print $2; exit}')
  par_socket=$(lscpu | awk -F: '/^Core\(s\) per socket/ {gsub(/ /,"",$2); print $2}')
  sockets=$(lscpu | awk -F: '/^Socket\(s\)/ {gsub(/ /,"",$2); print $2}')
  coeurs=$(( ${par_socket:-0} * ${sockets:-1} ))
  threads=$(nproc --all)

  echo "===== CONFIG PC ====="
  echo
  echo "PROCESSEUR : $cpu"
  echo "Coeurs / threads : $coeurs / $threads"
  echo

  # ----- Carte graphique
  if command -v lspci >/dev/null 2>&1; then
    lspci | grep -Ei 'vga|3d controller|display controller' | while read -r ligne; do
      slot=${ligne%% *}
      nom=${ligne#*: }
      marque=$(lspci -v -s "$slot" 2>/dev/null | awk -F': ' '/Subsystem:/ {print $2; exit}')
      echo "CARTE GRAPHIQUE : $nom"
      echo "Marque de la carte : ${marque:-inconnue}"
    done
  else
    echo "CARTE GRAPHIQUE : inconnue (outil lspci absent, paquet pciutils)"
  fi

  vram=""
  if command -v nvidia-smi >/dev/null 2>&1; then
    vram=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | awk '{printf "%d Go ", ($1/1024)+0.5}')
    nom_nv=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -n 1)
    drv_nv=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -n 1)
    [ -n "$nom_nv" ] && echo "Nom NVIDIA : $nom_nv"
    [ -n "$drv_nv" ] && echo "Driver NVIDIA : $drv_nv"
  fi
  if [ -z "$vram" ]; then
    for f in /sys/class/drm/card*/device/mem_info_vram_total; do
      [ -r "$f" ] && vram="$vram$(awk '{printf "%d Go ", ($1/1073741824)+0.5}' "$f")"
    done
  fi
  echo "VRAM : ${vram:-inconnue}"
  echo

  # ----- RAM
  total=$(awk '/^MemTotal/ {printf "%d", ($2/1048576)+0.5}' /proc/meminfo)
  echo "RAM TOTALE : $total Go"
  if [ -n "$RAM_DETAIL" ]; then
    echo "$RAM_DETAIL" | while IFS='|' read -r taille vit fab ref; do
      m=$(marque_ram "$ref")
      if [ -z "$m" ]; then
        case "$fab" in
          ""|Unknown*|Undefined*|0000*) m="marque inconnue" ;;
          *) m="$fab" ;;
        esac
      fi
      echo "  - $taille, $vit, $m, $ref"
    done
  else
    echo "  (detail des barrettes non lu)"
  fi
  echo

  # ----- Carte mere
  echo "CARTE MERE : $(dmi board_vendor) $(dmi board_name)"
  echo "BIOS : $(dmi bios_version) ($(dmi bios_vendor))"
  echo

  # ----- Stockage
  echo "STOCKAGE :"
  lsblk -dn -e 7,11 -o NAME,TYPE,SIZE,MODEL 2>/dev/null | awk '
    $2=="disk" && $1 !~ /^zram/ {
      t=$3; $1=""; $2=""; $3=""; sub(/^ +/,"")
      print "  - " ($0=="" ? "disque sans nom" : $0) " (" t ")"
    }'
  echo

  # ----- Systeme
  . /etc/os-release 2>/dev/null
  echo "SYSTEME : ${PRETTY_NAME:-Linux} (noyau $(uname -r))"
  echo "Modele PC : $(dmi sys_vendor) $(dmi product_name)"
  echo
  echo "===== FIN ====="
}

rapport | tee "$SORTIE"

# ----- Copie dans le presse-papiers si possible
if command -v wl-copy >/dev/null 2>&1; then
  wl-copy < "$SORTIE"; COPIE="copiee dans le presse-papiers"
elif command -v xclip >/dev/null 2>&1; then
  xclip -selection clipboard < "$SORTIE"; COPIE="copiee dans le presse-papiers"
elif command -v xsel >/dev/null 2>&1; then
  xsel -b < "$SORTIE"; COPIE="copiee dans le presse-papiers"
else
  COPIE="outil de presse-papiers indisponible"
fi

echo
echo "Termine. La configuration est $COPIE."
echo "Elle est aussi sauvegardee dans : $SORTIE"