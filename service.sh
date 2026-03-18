#!/system/bin/sh
MODPATH=${0%/*}
LOGFILE="$MODPATH/service.log"

log() {
    printf '%s - %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOGFILE"
}

log "service start"

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 5
done

log "boot complete"
log "replacing emoji fonts"
replaced=0
if [ -f "$MODPATH/system/fonts/NotoColorEmoji.ttf" ]; then
    for font in $(find /data/data /data/user/0 -iname "*emoji*.ttf" 2>/dev/null); do
        if [ -w "$font" ] && cp -f "$MODPATH/system/fonts/NotoColorEmoji.ttf" "$font" && chmod 644 "$font"; then
            replaced=$((replaced + 1))
        fi
    done
    log "emoji replace done: $replaced files"
else
    log "emoji replace skipped: source missing"
fi

log "updating Facebook & Messenger emoji files"
fb_ok=0
fb_fail=0
for pkg in com.facebook.orca com.facebook.katana com.facebook.lite com.facebook.mlite; do
    if [ -d "/data/data/$pkg" ]; then
        target="/data/data/$pkg/app_ras_blobs/FacebookEmoji.ttf"
        mkdir -p "/data/data/$pkg/app_ras_blobs"
        
        if cp -f "$MODPATH/system/fonts/NotoColorEmoji.ttf" "$target" && chmod 444 "$target"; then
            if chattr +i "$target" 2>/dev/null; then
                fb_ok=$((fb_ok + 1))
                log "$pkg: updated + immutable"
            else
                fb_ok=$((fb_ok + 1))
                log "$pkg: updated + read-only"
            fi
        else
            fb_fail=$((fb_fail + 1))
            log "$pkg: update failed"
        fi
    fi
done
log "Facebook update done: ok=$fb_ok fail=$fb_fail"

pm disable com.google.android.gms/com.google.android.gms.fonts.provider.FontsProvider >/dev/null 2>&1 && log "GMS FontsProvider disabled"
pm disable com.google.android.gms/com.google.android.gms.fonts.update.UpdateSchedulerService >/dev/null 2>&1 && log "GMS UpdateSchedulerService disabled"

rm -rf /data/fonts
find /data -type d -path "*com.google.android.gms/files/fonts*" -exec rm -rf {} + 2>/dev/null
log "GMS font cache cleared"

log "blocking Messenger font directories"
for dir in "/data/data/com.facebook.orca/files/fonts" "/data/user/0/com.facebook.orca/files/fonts"; do
    rm -rf "$dir" 2>/dev/null
    mkdir -p "$dir"
    chmod 000 "$dir" 2>/dev/null && log "blocked $dir"
done

for app in com.facebook.orca com.facebook.katana com.facebook.lite com.facebook.mlite; do
    am force-stop "$app" 2>/dev/null
done
log "Facebook apps force-stopped"

log "service end"