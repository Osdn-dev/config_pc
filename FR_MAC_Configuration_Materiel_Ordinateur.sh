#!/usr/bin/env bash
# FR_MAC_Connaitre_Tes_Pieces_PC.sh
# Affiche et sauvegarde la config du Mac. Ne modifie rien.

SORTIE="$PWD/config_pc.txt"

if [ "$(uname)" != "Darwin" ]; then
  echo "Ce script est fait pour macOS."
  exit 1
fi

hw=$(system_profiler SPHardwareDataType 2>/dev/null)
get() { echo "$hw" | awk -F': ' -v k="$1" '$1 ~ k {print $2; exit}'; }

rapport() {
  echo "===== CONFIG MAC ====="
  echo
  echo "MODELE : $(get 'Model Name') ($(get 'Model Identifier'))"
  echo "PROCESSEUR : $(sysctl -n machdep.cpu.brand_string)"
  echo "Coeurs / threads : $(sysctl -n hw.physicalcpu) / $(sysctl -n hw.logicalcpu)"
  echo
  echo "RAM TOTALE : $(sysctl -n hw.memsize | awk '{printf "%d", ($1/1073741824)+0.5}') Go"
  echo
  echo "CARTE GRAPHIQUE :"
  system_profiler SPDisplaysDataType 2>/dev/null | awk -F': ' '
    /Chipset Model/ {gsub(/^[ \t]+/,"",$2); print "  - " $2}
    /VRAM/ {gsub(/^[ \t]+/,"",$2); print "    VRAM : " $2}
    /Total Number of Cores/ {gsub(/^[ \t]+/,"",$2); print "    Coeurs GPU : " $2}'
  echo
  echo "STOCKAGE :"
  for d in $(diskutil list physical | awk '/^\/dev\/disk/ {print $1}'); do
    nom=$(diskutil info "$d" | awk -F': +' '/Device \/ Media Name/ {print $2; exit}')
    taille=$(diskutil info "$d" | awk -F': +' '/Disk Size/ {print $2; exit}' | sed 's/ (.*//')
    echo "  - $nom ($taille)"
  done
  echo
  echo "SYSTEME : macOS $(sw_vers -productVersion) (build $(sw_vers -buildVersion))"
  echo
  echo "===== FIN ====="
}

rapport | tee "$SORTIE"
pbcopy < "$SORTIE"

echo
echo "Termine. La config est copiee dans le presse-papiers (Cmd+V)."
echo "Elle est aussi sauvegardee dans : $SORTIE"
echo
read -r -p "Appuie sur Entree pour fermer"