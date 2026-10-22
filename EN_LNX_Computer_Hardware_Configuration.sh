#!/usr/bin/env bash
# Displays and saves the computer configuration. Does not modify the system.

export LC_ALL=C
export PATH="$PATH:/usr/sbin:/sbin"
OUTPUT="$PWD/pc_config.txt"

# ---------- RAM details (asks for a password only if accepted)
RAM_DETAILS=""
OK=0
SUDO=""
if command -v dmidecode >/dev/null 2>&1; then
  if [ "$(id -u)" -eq 0 ]; then
    OK=1
  elif sudo -n true 2>/dev/null; then
    SUDO="sudo"; OK=1
  else
    echo "To read RAM details (manufacturer, speed), the script needs your password."
    read -r -p "Do you want to continue and enter your password? (y/N) " reply
    case "$reply" in y|Y) SUDO="sudo"; OK=1 ;; esac
  fi
  if [ "$OK" -eq 1 ]; then
    RAM_DETAILS=$($SUDO dmidecode -t memory 2>/dev/null | awk '
      /^Memory Device/ { t=""; v=""; f=""; r="" }
      /^[ \t]+Size:/ { if ($2 ~ /^[0-9]+$/) t=$2" "$3; else t="" }
      /^[ \t]+Speed:/ { v=$2" "$3 }
      /^[ \t]+Manufacturer:/ { sub(/^[ \t]+Manufacturer:[ \t]*/,""); f=$0 }
      /^[ \t]+Part Number:/ { sub(/^[ \t]+Part Number:[ \t]*/,""); r=$0 }
      /^$/ { if (t!="") print t "|" v "|" f "|" r; t="" }
    ')
  fi
fi

ram_brand() {
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

report() {
  cpu=$(lscpu | awk -F: '/^Model name/ {gsub(/^[ \t]+/,"",$2); print $2; exit}')
  cores_per_socket=$(lscpu | awk -F: '/^Core\(s\) per socket/ {gsub(/ /,"",$2); print $2}')
  sockets=$(lscpu | awk -F: '/^Socket\(s\)/ {gsub(/ /,"",$2); print $2}')
  cores=$(( ${cores_per_socket:-0} * ${sockets:-1} ))
  threads=$(nproc --all)

  echo "===== PC CONFIGURATION ====="
  echo
  echo "PROCESSOR : $cpu"
  echo "Cores / threads : $cores / $threads"
  echo

  # ----- Graphics card
  if command -v lspci >/dev/null 2>&1; then
    lspci | grep -Ei 'vga|3d controller|display controller' | while read -r line; do
      slot=${line%% *}
      name=${line#*: }
      brand=$(lspci -v -s "$slot" 2>/dev/null | awk -F': ' '/Subsystem:/ {print $2; exit}')
      echo "GRAPHICS CARD : $name"
      echo "Card manufacturer : ${brand:-unknown}"
    done
  else
    echo "GRAPHICS CARD : unknown (lspci is missing; install the pciutils package)"
  fi

  vram=""
  if command -v nvidia-smi >/dev/null 2>&1; then
    vram=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | awk '{printf "%d GB ", ($1/1024)+0.5}')
    nvidia_name=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -n 1)
    nvidia_driver=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -n 1)
    [ -n "$nvidia_name" ] && echo "NVIDIA model : $nvidia_name"
    [ -n "$nvidia_driver" ] && echo "NVIDIA driver : $nvidia_driver"
  fi
  if [ -z "$vram" ]; then
    for f in /sys/class/drm/card*/device/mem_info_vram_total; do
      [ -r "$f" ] && vram="$vram$(awk '{printf "%d GB ", ($1/1073741824)+0.5}' "$f")"
    done
  fi
  echo "VRAM : ${vram:-unknown}"
  echo

  # ----- RAM
  total=$(awk '/^MemTotal/ {printf "%d", ($2/1048576)+0.5}' /proc/meminfo)
  echo "TOTAL RAM : $total GB"
  if [ -n "$RAM_DETAILS" ]; then
    echo "$RAM_DETAILS" | while IFS='|' read -r size speed manufacturer part_number; do
      brand=$(ram_brand "$part_number")
      if [ -z "$brand" ]; then
        case "$manufacturer" in
          ""|Unknown*|Undefined*|0000*) brand="unknown brand" ;;
          *) brand="$manufacturer" ;;
        esac
      fi
      echo "  - $size, $speed, $brand, $part_number"
    done
  else
    echo "  (memory module details not read)"
  fi
  echo

  # ----- Motherboard
  echo "MOTHERBOARD : $(dmi board_vendor) $(dmi board_name)"
  echo "BIOS : $(dmi bios_version) ($(dmi bios_vendor))"
  echo

  # ----- Storage
  echo "STORAGE:"
  lsblk -dn -e 7,11 -o NAME,TYPE,SIZE,MODEL 2>/dev/null | awk '
    $2=="disk" && $1 !~ /^zram/ {
      t=$3; $1=""; $2=""; $3=""; sub(/^ +/,"")
      print "  - " ($0=="" ? "unnamed drive" : $0) " (" t ")"
    }'
  echo

  # ----- Operating system
  . /etc/os-release 2>/dev/null
  echo "SYSTEM : ${PRETTY_NAME:-Linux} (kernel $(uname -r))"
  echo "PC model : $(dmi sys_vendor) $(dmi product_name)"
  echo
  echo "===== END ====="
}

report | tee "$OUTPUT"

# ----- Copy to the clipboard when possible
if command -v wl-copy >/dev/null 2>&1; then
  wl-copy < "$OUTPUT"; CLIPBOARD_STATUS="copied to the clipboard"
elif command -v xclip >/dev/null 2>&1; then
  xclip -selection clipboard < "$OUTPUT"; CLIPBOARD_STATUS="copied to the clipboard"
elif command -v xsel >/dev/null 2>&1; then
  xsel -b < "$OUTPUT"; CLIPBOARD_STATUS="copied to the clipboard"
else
  CLIPBOARD_STATUS="clipboard utility unavailable"
fi

echo
echo "Done. The configuration was $CLIPBOARD_STATUS."
echo "It was also saved to: $OUTPUT"
