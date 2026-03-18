#!/system/bin/sh

export PATH="/data/adb/ksu/bin:/data/adb/magisk:/system/bin:/system/xbin:$PATH"

if [ -n "$MODDIR" ] && [ -d "$MODDIR" ]; then
    MODPATH="$MODDIR"
else
    MODPATH="${0%/*}"
    [ "$MODPATH" = "$0" ] && MODPATH="$(pwd)"
    MODPATH="$(cd "$MODPATH" 2>/dev/null && pwd)"
fi

set +o standalone 2>/dev/null
unset ASH_STANDALONE 2>/dev/null

SCRIPT="$MODPATH/service.sh"
if [ ! -f "$SCRIPT" ]; then
    echo "Error: service.sh not found" >&2
    exit 1
fi

if ! sh "$SCRIPT"; then
    echo "Error: service.sh failed" >&2
    exit 1
fi

echo "Service run complete"

exit 0