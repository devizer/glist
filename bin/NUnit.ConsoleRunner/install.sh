#!/usr/bin/env bash
# export NUNIT_TEST_RUNNER_INSTALL_DIR=/opt/nunit.consolerunner NUNIT_TEST_RUNNER_VERSION=3.18.2
# url=https://raw.githubusercontent.com/devizer/glist/master/bin/NUnit.ConsoleRunner/install.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -sfSL $url) | bash

if [[ -z "${NUNIT_TEST_RUNNER_INSTALL_DIR:-}" ]]; then
  defult_target_dir=/opt/nunit.consolerunner
  if [[ -n "${TERMUX_VERSION}" ]] && [[ -n "${PREFIX}" ]] && [[ -d "${PREFIX}" ]]; then
    defult_target_dir="$PREFIX/share/nunit.consolerunner"
  fi

  if [[ "$(uname -s)" == *"MINGW"* ]] && [[ -d "C:\\Windows" ]]; then
    defult_target_dir="C:\\Windows"
  fi

  NUNIT_TEST_RUNNER_INSTALL_DIR="$defult_target_dir"
fi

if [[ -z "${LINKS_FOLDER:-}" ]]; then
  defult_target_dir=/usr/local/bin
  if [[ -n "${TERMUX_VERSION}" ]] && [[ -n "${PREFIX}" ]] && [[ -d "${PREFIX}" ]]; then
    defult_target_dir="$PREFIX/bin"
  fi

  if [[ "$(uname -s)" == *"MINGW"* ]] && [[ -d "C:\\Windows" ]]; then
    defult_target_dir="C:\\Windows"
  fi

  LINKS_FOLDER="$defult_target_dir"
fi

export NUNIT_TEST_RUNNER_VERSION="${NUNIT_TEST_RUNNER_VERSION:-3.18.2}"
export NUNIT_TEST_RUNNER_INSTALL_DIR="${NUNIT_TEST_RUNNER_INSTALL_DIR}/$NUNIT_TEST_RUNNER_VERSION"
export LINKS_FOLDER

echo "Downloading NUnit.ConsoleRunner v$NUNIT_TEST_RUNNER_VERSION to '$NUNIT_TEST_RUNNER_INSTALL_DIR' with link as $LINKS_FOLDER/nunit3-console"

# export NET_TEST_RUNNERS_INSTALL_DIR=/opt;
tmp="${TMPDIR:-/tmp}"
archive="https://raw.githubusercontent.com/devizer/glist/master/bin/NUnit.ConsoleRunner/NUnit.ConsoleRunner-v${NUNIT_TEST_RUNNER_VERSION}.tar.gz";
cmd="(wget -O "$tmp/nunit.consolerunner.tar.gz" --no-check-certificate "$archive" 2>/dev/null || curl -o "$tmp/nunit.consolerunner.tar.gz" -kfSL "$archive")"
eval "$cmd" || eval "$cmd" || eval "$cmd" || rm -f "$tmp/nunit.consolerunner.tar.gz"
sudo mkdir -p "$NUNIT_TEST_RUNNER_INSTALL_DIR"
set -eu
pushd "$NUNIT_TEST_RUNNER_INSTALL_DIR" >/dev/null
sudo tar xzf "$tmp/nunit.consolerunner.tar.gz"
rm -f "$tmp/nunit.consolerunner.tar.gz"
echo '#!/usr/bin/env bash
      set -e; mono "'$NUNIT_TEST_RUNNER_INSTALL_DIR'/nunit3-console.exe" "$@" 
' | sudo tee "$LINKS_FOLDER/nunit3-console" > /dev/null
sudo chmod +x "$LINKS_FOLDER/nunit3-console"
popd >/dev/null
v="/tmp/nunit3c.hlp.$RANDOM"
nunit3-console > "$v"
echo "Version Installed: $(cat "$v" | head -1)"
rm -f "$v"
