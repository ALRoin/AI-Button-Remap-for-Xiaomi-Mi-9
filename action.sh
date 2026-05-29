#!/system/bin/sh

MODDIR=${0%/*}
TMPDIR=/data/local/tmp

TARGET_FILE="$MODDIR/system/usr/keylayout/gpio-keys.kl"

if [ ! -f "$TARGET_FILE" ]; then
  echo "! Error: gpio-keys.kl not found!"
  echo "! Checked path: $TARGET_FILE"
  exit 1
fi

echo "Here's the list of available functions:"
echo ""

check_key() {
  local delay=${1:-10}

  rm -f $TMPDIR/events

  timeout $delay getevent -lqc 1 > $TMPDIR/events 2>/dev/null

  if grep -q "KEY_VOLUMEUP *DOWN" $TMPDIR/events; then
      return 0
  elif grep -q "KEY_VOLUMEDOWN *DOWN" $TMPDIR/events; then
      return 1
  fi

  return 2
}

get_name() {
  case $1 in
    1) echo "Camera";;
    2) echo "Screenshot";;
    3) echo "Google Search";;
    4) echo "Google Assistant";;
    5) echo "Call";;
    6) echo "Contacts";;
    7) echo "Music Player";;
    8) echo "Mute/Unmute Media";;
    9) echo "Play/Pause Media";;
    10) echo "Next Media";;
    11) echo "Recent Apps";;
    12) echo "Open/Close Quick Settings";;
    13) echo "Internet Browser";;
    14) echo "Calendar";;
    15) echo "Calculator";;
    16) echo "Power Button";;
    17) echo "No Function";;
  esac
}

get_code() {
  case $1 in
    1) echo "CAMERA";;
    2) echo "SYSRQ";;
    3) echo "SEARCH";;
    4) echo "VOICE_ASSIST";;
    5) echo "CALL";;
    6) echo "CONTACTS";;
    7) echo "MUSIC";;
    8) echo "VOLUME_MUTE";;
    9) echo "MEDIA_PLAY_PAUSE";;
    10) echo "MEDIA_NEXT";;
    11) echo "APP_SWITCH";;
    12) echo "QPANEL_ON_OFF";;
    13) echo "EXPLORER";;
    14) echo "CALENDAR";;
    15) echo "CALCULATOR";;
    16) echo "POWER";;
    17) echo "NOF";;
  esac
}

MAX_ITEMS=17

i=1
while [ $i -le $MAX_ITEMS ]; do
  echo "  - $(get_name $i)"
  i=$((i + 1))
done

echo ""
echo "----------------------------------"
echo " PRESS VOLUME DOWN TO BEGIN SETUP "
echo "----------------------------------"

while true; do
  check_key 60
  if [ $? -eq 1 ]; then
    break
  fi
done

echo ""
echo "ENTERING SELECTION MODE"
echo "  Vol UP   = Select / Confirm"
echo "  Vol DOWN = Next Option"
echo ""

POS=1
echo "Current Choice: [ $(get_name $POS) ]"

while true; do
  check_key 300
  INPUT=$?

  if [ $INPUT -eq 0 ]; then

    SELECTED_NAME=$(get_name $POS)
    SELECTED_CODE=$(get_code $POS)

    echo ""
    echo "**********************************"
    echo " SELECTED: $SELECTED_NAME"
    echo "**********************************"
    break

  elif [ $INPUT -eq 1 ]; then

    POS=$((POS + 1))
    if [ $POS -gt $MAX_ITEMS ]; then
      POS=1
    fi

    echo "Current Choice: [ $(get_name $POS) ]"
  fi
done

echo "- Configuring gpio-keys.kl..."

if grep -q "key 689" "$TARGET_FILE"; then
    sed -i "s/^key 689.*/key 689   $SELECTED_CODE/" "$TARGET_FILE"
    echo "- Remapped key 689 to $SELECTED_NAME"
else
    echo "key 689   $SELECTED_CODE" >> "$TARGET_FILE"
    echo "- Key 689 not found, appended new mapping."
fi

chmod 0644 "$TARGET_FILE"

echo "- The button function was successfully changed. Reboot the phone to apply the changes."