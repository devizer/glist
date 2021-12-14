# https://stackoverflow.com/questions/43291389/using-jq-to-assign-multiple-output-variables
API_BASE="${API_BASE:-https://dev.azure.com/devizer/Universe.CpuUsage}"
ARTIFACT_NAME="${ARTIFACT_NAME:-BinTests}"
API_PAT="${API_PAT:-}"; # empty for public project, mandatory for private
# PIPELINE_NAME="" - optional of more then one pipeline produce same ARTIFACT_NAME


function GetNewestArtifact() {
  ARTIFACT_URL=
  ARTIFACT_ID=
  local builds=$(GetBuilds)
  local build_id build_name pipeline_name build_status build_result
  while IFS="|" read -r build_id build_name pipeline_name build_status build_result; do
    local artifacts=$(GetArtifacts "$build_id")
    local artifact_id artifact_name artifact_url
    while IFS="|" read -r artifact_id artifact_name artifact_url; do
      echo "try the [$build_id: $build_name] build of [$(basename $API_BASE)]"
      if [[ "$artifact_name" == "$ARTIFACT_NAME" ]]; then
        if [[ -n "$PIPELINE_NAME" ]] && [[ "$PIPELINE_NAME" != "$pipeline_name" ]]; then
          continue;
        fi
        BUILD_ID="$build_id"
        BUILD_NAME="$build_name"
        BUILD_STATUS="$build_status"
        BUILD_RESULT="$build_result"
        ARTIFACT_ID="$artifact_id"
        ARTIFACT_URL="$artifact_url"
        FetchCommit $build_id
        Say "The Newest '$ARTIFACT_NAME' Artifact:
Build:   $build_id $build_name
Commit:  $COMMIT_HASH
Author:  $COMMIT_AUTHOR
Time:    $COMMIT_TIMESTAMP
Link:    $COMMIT_LINK
Message: $COMMIT_MESSAGE
Url:     $artifact_url"
        break 2
      fi
    done < "$artifacts"
  done < "$builds"
}

function _init_azure_api_() {
  if [[ -z "$IODIR" ]]; then
    TMPDIR="${TMPDIR:-/tmp}"
    mkdir -p "$TMPDIR/azure-api"
    System="${System:-$(uname -s)}"
    if [[ "$System" == "Darwin" ]]; then
      IODIR="$(mktemp -t session)"; rm -rf "$IODIR"; IODIR=$(basename $IODIR);
    else
      IODIR="$(mktemp -t -d --tmpdir=$TMPDIR/azure-api session.XXXXXXXX)"
    fi
    echo IODIR: $IODIR
  fi
}; _init_azure_api_

function GetTempFileFullName() {
  local template=$1
  local ret;
  System="${System:-$(uname -s)}"
  if [[ "$System" == "Darwin" ]]; then
    # export _CS_DARWIN_USER_TEMP_DIR="$IODIR"
    ret=$(mktemp -t $template.$IODIR)
  else
    ret=$(mktemp -t --tmpdir=$IODIR $template.XXXXX)
  fi
  rm -f "$ret" || true
  echo "$ret"
}

function DownloadViaApi() {
  local url=$1
  local file=$2;
  local header1="";
  local header2="";
  if [[ -n "$API_PAT" ]]; then 
    local B64_PAT=$(printf "%s"":$API_PAT" | base64)
    header1='--header="Authorization: Basic '${B64_PAT}'"'
    header2='--header "Authorization: Basic '${B64_PAT}'"'
  fi
  local progress1="2>/dev/null";
  local progress2="-s"
  if [[ -z "API_SHOW_PROGRESS" ]]; then
    progress1=""
    progress2=""
  fi
  eval try-and-retry wget $header1 --no-check-certificate -O "$file" "$url" $progress1 || eval try-and-retry curl $header2 $progress2 -kSL -o "$file" "$url"
  echo "$file"
}

function GetBuilds() {
  local url="${API_BASE}/_apis/build/builds?api-version=6.0"
  local file=$(GetTempFileFullName builds);
  local json=$(DownloadViaApi "$url" "$file.json")
  f='.value | map({"id":.id|tostring, "buildNumber":.buildNumber, p:.definition?.name?, r:.result, s:.status}) | map([.id, .buildNumber, .p, .r, .s] | join("|")) | join("\n") '
  jq -r "$f" "$file.json" | sort -r -k1 -n -t"|" > "$file.txt"
  echo "$file.txt"
}

function GetArtifacts() {
  local buildId=$1
  local url="${API_BASE}/_apis/build/builds/${buildId}/artifacts?api-version=6.0"
  local file=$(GetTempFileFullName artifacts-$buildId);
  local json=$(DownloadViaApi "$url" "$file.json")
  f='.value | map({"id":.id|tostring, "name":.name, "url":.resource?.downloadUrl?}) | map([.id, .name, .url] | join("|")) | join("\n")'
  jq -r "$f" "$file.json" > "$file.txt"
  echo "$file.txt"
}

function FetchCommit() {
  local buildId=$1
  COMMIT_HASH=
  COMMIT_MESSAGE=
  COMMIT_AUTHOR=
  COMMIT_TIMESTAMP=
  COMMIT_LINK=
  local url="${API_BASE}/_apis/build/builds/${buildId}/changes?api-version=6.0"
  local file=$(GetTempFileFullName changes-$buildId);
  local json=$(DownloadViaApi "$url" "$file.json")
  f='.value | map({"id":.id, "m":.message, "a":.author?.displayName?, "t":.timestamp, "u":.displayUri}) | map([.id, .m, .a, .t, .u] | join("|")) | join("\n")'
  jq -r "$f" "$file.json" > "$file.txt"
  COMMIT_HASH=$(cat "$file.json" | jq -r '.value[0].id')
  COMMIT_MESSAGE=$(cat "$file.json" | jq -r '.value[0].message')
  COMMIT_AUTHOR=$(cat "$file.json" | jq -r '.value[0].author?.displayName?')
  COMMIT_TIMESTAMP=$(cat "$file.json" | jq -r '.value[0].timestamp?')
  COMMIT_LINK=$(cat "$file.json" | jq -r '.value[0].displayUri?')
}


# GetNewestArtifact
