#!/usr/bin/env bash
# Run-Remote-Script https://raw.githubusercontent.com/devizer/glist/master/Pack-each-Artifact-per-Archive.sh
set -eu; set -o pipefail
COMPRESSION_LEVEL="${COMPRESSION_LEVEL:-6}"
Say --Reset-Stopwatch
Say "Pack Artifact Per Archive: [$(pwd -P)]; Compression Level = $COMPRESSION_LEVEL"
log=$(mktemp)
list=$(mktemp)
find . -maxdepth 1 -type d -not -path '.' > "$list"
count=$(wc -l)
index=0
cat "$list" | while IFS= read -r folder; do
    index=$((index+1))
    echo "[$index of $count] Processing folder $folder"
    startAt=$(Get-Global-Seconds)
    err=""
    7z a -ms=on -mqs=on -bd -mx=$COMPRESSION_LEVEL "${folder}.7z" "$folder" 2>&1 >"$log" || err=err
    if [[ -n "$err" ]]; then
      Colorize Red "7-zip compression failed"
      cat "$log"
      rm -f "$log" 2>/dev/null || true
      return 1
    fi
    rm -f "$log" 2>/dev/null || true
    seconds=$(( $(Get-Global-Seconds) - startAt ))
    seconds_string="$seconds seconds"; [[ "$seconds" == "1" ]] && seconds_string="1 second"
    Colorize LightGreen "OK. ${folder}.7z is $(Format-Thousand "$(Get-File-Size "${folder}.7z")") bytes (took $seconds_string)"
    rm -rf "$folder" 2>/dev/null || rm -rf "$folder" 2>/dev/null || rm -rf "$folder"
done
Say "Done: $count folder(s) are compressed"
