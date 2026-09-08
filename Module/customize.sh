KEYLAYOUT_DIRS="/system/usr/keylayout /system_ext/usr/keylayout /vendor/usr/keylayout /odm/usr/keylayout"

SRC_FILE=""
SRC_NAME=""

for dir in $KEYLAYOUT_DIRS; do
  if [ -f "$dir/gpio-keys.kl" ]; then
    SRC_FILE="$dir/gpio-keys.kl"
    SRC_NAME="gpio-keys.kl"
    break
  fi
done

if [ -z "$SRC_FILE" ]; then
  for dir in $KEYLAYOUT_DIRS; do
    if [ -f "$dir/Generic.kl" ]; then
      SRC_FILE="$dir/Generic.kl"
      SRC_NAME="Generic.kl"
      break
    fi
  done
fi

if [ -z "$SRC_FILE" ]; then
  ui_print "! Error: Neither gpio-keys.kl nor Generic.kl was found on this device!"
  ui_print "! Checked: $KEYLAYOUT_DIRS"
  ls -R $MODPATH
  abort
fi

ui_print "- Detected target file: $SRC_FILE"

mkdir -p "$MODPATH/system/usr/keylayout"
rm -f "$MODPATH/system/usr/keylayout/gpio-keys.kl" "$MODPATH/system/usr/keylayout/Generic.kl"
cp -f "$SRC_FILE" "$MODPATH/system/usr/keylayout/$SRC_NAME"

TARGET_FILE="$MODPATH/system/usr/keylayout/$SRC_NAME"

if [ ! -f "$TARGET_FILE" ]; then
  ui_print "! Error: $SRC_NAME not found after copying!"
  ui_print "! Checked path: $TARGET_FILE"
  # 
  ls -R $MODPATH
  abort
fi

ui_print "- File extracted successfully."

# ------------------------------------------------------
ui_print ""
ui_print ""
ui_print "Here's the list of available functions:"
ui_print ""
# ------------------------------------------------------

check_key() {
  local delay=${1:-10}
  
  # 
  rm -f $TMPDIR/events

  # 
  # 
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

# ------------------------------------------------------

i=1
while [ $i -le $MAX_ITEMS ]; do
  ui_print "  - $(get_name $i)"
  i=$((i + 1))
done

ui_print ""
ui_print "----------------------------------"
ui_print " PRESS VOLUME DOWN TO BEGIN SETUP "
ui_print "----------------------------------"

while true; do
  check_key 60
  if [ $? -eq 1 ]; then
    break
  fi
done

# ------------------------------------------------------

ui_print ""
ui_print "ENTERING SELECTION MODE"
ui_print "  Vol UP   = Select / Confirm"
ui_print "  Vol DOWN = Next Option"
ui_print ""

POS=1
ui_print "Current Choice: [ $(get_name $POS) ]"

while true; do
  check_key 300
  INPUT=$?
  
  if [ $INPUT -eq 0 ]; then

    SELECTED_NAME=$(get_name $POS)
    SELECTED_CODE=$(get_code $POS)
    ui_print ""
    ui_print "**********************************"
    ui_print " SELECTED: $SELECTED_NAME"
    ui_print "**********************************"
    break
    
  elif [ $INPUT -eq 1 ]; then

    POS=$((POS + 1))
    if [ $POS -gt $MAX_ITEMS ]; then
      POS=1
    fi
    ui_print "Current Choice: [ $(get_name $POS) ]"
  fi
done

# ------------------------------------------------------
# 
# ------------------------------------------------------

ui_print "- Configuring $SRC_NAME..."

if grep -q "key 689" "$TARGET_FILE"; then
    sed -i "s/^key 689.*/key 689   $SELECTED_CODE/" "$TARGET_FILE"
    ui_print "- Remapped key 689 to $SELECTED_NAME"
else
    
    echo "key 689   $SELECTED_CODE" >> "$TARGET_FILE"
    ui_print "- Key 689 not found, appended new mapping."
fi

#
set_perm "$TARGET_FILE" 0 0 0644

ui_print "The button function was successfully changed. Reboot the phone to apply the changes."