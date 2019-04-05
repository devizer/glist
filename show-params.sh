#!/usr/bin/env bash
_dotnet=
_node=
_pwsh=
while [ $# -ne 0 ]; do
    param="$1"
    case "$param" in
        dotnet|node|pwsh)
            eval '$'_$param=yes
            channel="$1"
            ;;
        *)
            echo "Unknown argument \`$param\`"
    esac

    echo Parameter: $param
    shift
done
echo Install dotnet: [$_dotnet]
echo Install node: [$_node]
echo Install powershell: [$_pwsh]

