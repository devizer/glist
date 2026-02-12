#!/usr/bin/env bash
# Run-Remote-Script https://raw.githubusercontent.com/devizer/glist/master/Pack-each-Artifact-per-Archive.sh
set -eu; set -o pipefail
COMPRESSION_LEVEL="${COMPRESSION_LEVEL:-6}"
Say "Pack Artifact Per Archive: [$(pwd -P)]; Compression Level = $COMPRESSION_LEVEL"
find . -maxdepth 1 -type d -not -path '.' | while read -r folder; do
    echo "Processing folder $folder"
    startAt=$(Get-Global-Seconds)
    7z a -ms=on -mqs=0 -bdo0 -bdp0 -mx=$COMPRESSION_LEVEL "${folder}.7z" "$folder"
    seconds=$(( $(Get-Global-Seconds) - startAt ))
    seconds_string="$seconds seconds"; [[ "$seconds" == "1" ]] && seconds_string="1 second"
    Colorize LightGreen "$(Format-Thousand "$(Get-File-Size "${folder}.7z")") bytes (took $seconds_string)"
done
