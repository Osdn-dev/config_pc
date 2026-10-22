#!/usr/bin/env bash
# Displays and saves the Mac configuration. Does not modify the system.

OUTPUT="$PWD/pc_config.txt"

if [ "$(uname)" != "Darwin" ]; then
  echo "This script is for macOS."
  exit 1
fi

hw=$(system_profiler SPHardwareDataType 2>/dev/null)
get() { echo "$hw" | awk -F': ' -v k="$1" '$1 ~ k {print $2; exit}'; }

report() {
  echo "===== MAC CONFIGURATION ====="
  echo
  echo "MODEL : $(get 'Model Name') ($(get 'Model Identifier'))"
  echo "PROCESSOR : $(sysctl -n machdep.cpu.brand_string)"
  echo "Cores / threads : $(sysctl -n hw.physicalcpu) / $(sysctl -n hw.logicalcpu)"
  echo
  echo "TOTAL RAM : $(sysctl -n hw.memsize | awk '{printf "%d", ($1/1073741824)+0.5}') GB"
  echo
  echo "GRAPHICS CARD:"
  system_profiler SPDisplaysDataType 2>/dev/null | awk -F': ' '
    /Chipset Model/ {gsub(/^[ \t]+/,"",$2); print "  - " $2}
    /VRAM/ {gsub(/^[ \t]+/,"",$2); print "    VRAM : " $2}
    /Total Number of Cores/ {gsub(/^[ \t]+/,"",$2); print "    GPU cores : " $2}'
  echo
  echo "STORAGE:"
  for d in $(diskutil list physical | awk '/^\/dev\/disk/ {print $1}'); do
    name=$(diskutil info "$d" | awk -F': +' '/Device \/ Media Name/ {print $2; exit}')
    size=$(diskutil info "$d" | awk -F': +' '/Disk Size/ {print $2; exit}' | sed 's/ (.*//')
    echo "  - $name ($size)"
  done
  echo
  echo "SYSTEM : macOS $(sw_vers -productVersion) (build $(sw_vers -buildVersion))"
  echo
  echo "===== END ====="
}

report | tee "$OUTPUT"
pbcopy < "$OUTPUT"

echo
echo "Done. The configuration was copied to the clipboard (Cmd+V)."
echo "It was also saved to: $OUTPUT"
echo
read -r -p "Press Enter to close"
