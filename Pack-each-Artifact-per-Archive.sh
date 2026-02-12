#!/usr/bin/env bash
# Run-Remote-Script https://raw.githubusercontent.com/devizer/glist/master/Pack-each-Artifact-per-Archive.sh
set -eu; set -o pipefail

COMPRESSION_LEVEL="${COMPRESSION_LEVEL:-6}"
COMPRESS_TYPE="${COMPRESS_TYPE:-7z}"
COMPRESS_METHOD="${COMPRESS_METHOD:-lzma2}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        # Уровень: -1 ... -9
        -[1-9]) 
            COMPRESSION_LEVEL="${1#-}" 
            ;;
        # Метод
        -lzma|-lzma2|-ppmd|-bzip2) 
            COMPRESS_METHOD="${1#-}" 
            ;;
        # Тип
        -7z|-tar.7z|-xz|-zip|-gz) 
            COMPRESS_TYPE="${1#-}" 
            ;;
        *) 
            echo "Unknown option: $1" >&2
            ;;
    esac
    shift
done

# echo "Level:  $COMPRESSION_LEVEL"
# echo "Type:   $COMPRESS_TYPE"
# echo "Method: $COMPRESS_METHOD"

method_string=", Method=$COMPRESS_METHOD"; [[ $COMPRESS_TYPE != "7z" ]] && method_string=""
Say --Reset-Stopwatch
Say "Pack Artifact Per Archive: [$(pwd -P)]; Compression Level = $COMPRESSION_LEVEL, Type = ${COMPRESS_TYPE}${method_string}"
log=$(mktemp)
list=$(mktemp)
find . -maxdepth 1 -type d -not -path '.' > "$list"
count=$(cat "$list" | wc -l)
index=0
cat "$list" | while IFS= read -r line; do
    index=$((index+1))
    folder="$(basename "$line")"
    echo "[$index of $count] Processing folder '$folder'"
    startAt=$(Get-Global-Seconds)
    err=""
    if [[ "$COMPRESS_TYPE" == "7z" ]]; then
        archive="${folder}.7z"
        7z a -ms=on -mqs=on -bd -m0=$COMPRESS_METHOD -mx=$COMPRESSION_LEVEL "$archive" "$folder" 2>&1 >"$log" || err=err
    elif [[ "$COMPRESS_TYPE" == "tar.7z" ]]; then
        archive="${folder}.tar.7z"
        tar cf - "$folder" | 7z a -m0=$COMPRESS_METHOD -t7z -mmt=$(nproc) -mx=$COMPRESSION_LEVEL -si "$archive" 2>&1 >"$log" || err=err
    elif [[ "$COMPRESS_TYPE" == "xz" ]]; then
        archive="${folder}.tar.xz"
        tar cf - "$folder" | 7z a dummy -txz -mmt=$(nproc) -mx=$COMPRESSION_LEVEL -si -so > "$archive" || err=err
    else
       Colorize Red "Compression Type '$COMPRESS_TYPE' is unknown"
       return 2
    fi
    if [[ -n "$err" ]]; then
      Colorize Red "$COMPRESS_TYPE compression failed"
      cat "$log"
      rm -f "$log" 2>/dev/null || true
      return 1
    fi
    rm -f "$log" 2>/dev/null || true
    seconds=$(( $(Get-Global-Seconds) - startAt ))
    seconds_string="$seconds seconds"; [[ "$seconds" == "1" ]] && seconds_string="1 second"
    Colorize LightGreen "OK. "$archive" is $(Format-Thousand "$(Get-File-Size "$archive")") bytes (took $seconds_string)"
    rm -rf "$folder" 2>/dev/null || rm -rf "$folder" 2>/dev/null || rm -rf "$folder"
done
Say "Done: $count folder(s) are compressed"
