#!/usr/bin/env bash
# url=https://raw.githubusercontent.com/devizer/glist/master/bin/net-test-runners.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -sSL $url) | bash

if [[ -z "${NET_TEST_RUNNERS_INSTALL_DIR:-}" ]]; then
  defult_target_dir=/opt
  if [[ -n "${TERMUX_VERSION}" ]] && [[ -n "${PREFIX}" ]] && [[ -d "${PREFIX}" ]]; then
    defult_target_dir="$PREFIX/share/net-test-runners"
  fi

  if [[ "$(uname -s)" == *"MINGW"* ]] && [[ -d "C:\\Windows" ]]; then
    defult_target_dir="C:\\Windows"
  fi

  NET_TEST_RUNNERS_INSTALL_DIR="$defult_target_dir"
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

export NET_TEST_RUNNERS_INSTALL_DIR
export LINKS_FOLDER


# export NET_TEST_RUNNERS_INSTALL_DIR=/opt;
tmp="${TMPDIR:-/tmp}"
archive=https://raw.githubusercontent.com/devizer/glist/master/bin/net-test-runners.tar.gz;
cmd="(wget -O $tmp/net-test-runners.tar.gz --no-check-certificate $archive 2>/dev/null || curl -o $tmp/net-test-runners.tar.gz -kSL $archive)"
eval "$cmd" || eval "$cmd" || eval "$cmd" || rm -f $tmp/net-test-runners.tar.gz
sudo mkdir -p "$NET_TEST_RUNNERS_INSTALL_DIR"
pushd "$NET_TEST_RUNNERS_INSTALL_DIR" >/dev/null
sudo tar xzf $tmp/net-test-runners.tar.gz
cd net-test-runners 
bash link-unit-test-runners.sh 
popd >/dev/null

