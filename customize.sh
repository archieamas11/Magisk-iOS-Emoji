#!/system/bin/sh

AUTOMOUNT=true
SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=true

ui_print "iOS Emoji 18.4"

MODPATH=${0%/*}
FONT_DIR="$MODPATH/system/fonts"
FONT_EMOJI="NotoColorEmoji.ttf"

ui_print "- Extracting files"
unzip -o "$ZIPFILE" 'system/*' -d "$MODPATH" >&2 || {
    ui_print "! Extract failed"
    exit 1
}

ui_print "- Installing emoji fonts"

variants="SamsungColorEmoji.ttf LGNotoColorEmoji.ttf HTC_ColorEmoji.ttf AndroidEmoji-htc.ttf ColorUniEmoji.ttf DcmColorEmoji.ttf CombinedColorEmoji.ttf NotoColorEmojiLegacy.ttf"
updated=0
failed=0

for font in $variants; do
    if [ -f "/system/fonts/$font" ]; then
        if cp -f "$FONT_DIR/$FONT_EMOJI" "$FONT_DIR/$font"; then
            updated=$((updated + 1))
        else
            failed=$((failed + 1))
        fi
    fi
done
ui_print "  Updated: $updated, Failed: $failed"

ui_print "- Linking fonts.xml entries"
[[ -d /sbin/.core/mirror ]] && MIRRORPATH=/sbin/.core/mirror || unset MIRRORPATH
FONTS=/system/etc/fonts.xml
if [ -f "$MIRRORPATH$FONTS" ]; then
    FONTFILES=$(sed -ne '/<family lang="und-Zsye".*>/,/<\/family>/ {s/.*<font weight="400" style="normal">\(.*\)<\/font>.*/\1/p;}' "$MIRRORPATH$FONTS")
    for font in $FONTFILES; do
        ln -sf /system/fonts/NotoColorEmoji.ttf "$MODPATH/system/fonts/$font" 2>/dev/null
    done
    ui_print "  fonts.xml links created"
else
    ui_print "  fonts.xml not found"
fi

if [ -d "/data/fonts" ]; then
    rm -rf "/data/fonts"
    ui_print "  Cleared /data/fonts"
fi

ui_print "- Clearing Gboard cache"
for subpath in /cache /code_cache /app_webview /files/GCache; do
    rm -rf "/data/data/com.google.android.inputmethod.latin${subpath}" 2>/dev/null
done
am force-stop com.google.android.inputmethod.latin 2>/dev/null
ui_print "  Gboard cache cleared"

ui_print "- Setting permissions"
set_perm_recursive "$MODPATH" 0 0 0755 0644

ui_print "Install complete"
ui_print "- Reboot required"

OVERLAY_IMAGE_EXTRA=0
OVERLAY_IMAGE_SHRINK=true
if [ -f "/data/adb/modules/magisk_overlayfs/util_functions.sh" ] && \
    /data/adb/modules/magisk_overlayfs/overlayfs_system --test; then
    ui_print "- Enabling OverlayFS"
    . /data/adb/modules/magisk_overlayfs/util_functions.sh
    support_overlayfs && rm -rf "$MODPATH"/system
fi