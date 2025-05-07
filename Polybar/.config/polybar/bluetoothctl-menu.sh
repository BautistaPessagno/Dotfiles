#!/usr/bin/env bash
# ~/.config/polybar/scripts/bluetoothctl-menu.sh

# Nombre de tu adaptador (casi siempre hci0)
ADAPTER="hci0"

# Función para comprobar si el adaptador está encendido
get_power_state() {
  bluetoothctl show "$ADAPTER" | awk -F ': ' '/Powered/ { print $2 }'
}

# Función para listar dispositivos emparejados
list_paired() {
  bluetoothctl paired-devices | cut -d ' ' -f 2,3- 
}

# Función para mostrar menú y conectar/desconectar
device_menu() {
  local devices choice mac cmd
  mapfile -t devices < <( list_paired )
  choice=$(printf '%s\n' "${devices[@]}" | rofi -dmenu -i -p "BT Devices")
  [[ -z "$choice" ]] && exit 0
  mac=${choice%% *}
  # Comprobar si ya está conectado
  if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
    cmd="disconnect $mac"
  else
    cmd="connect $mac"
  fi
  echo -e "Pairing with $mac…"
  bluetoothctl $cmd >/dev/null
}

case "$1" in
  --toggle)
    # Enciende/apaga el adaptador
    if [[ "$(get_power_state)" == "yes" ]]; then
      bluetoothctl power off
    else
      bluetoothctl power on
    fi
    ;;
  --menu)
    device_menu
    ;;
  *)
    # Al mostrar en Polybar, solo devolvemos un icono según estado
    if [[ "$(get_power_state)" == "yes" ]]; then
      echo "  On"
    else
      echo "  Off"
    fi
    ;;
esac

