#!/usr/bin/env bash
# url=https://raw.githubusercontent.com/devizer/glist/master/bin/net-test-runners.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -sSL $url) | bash
export NET_TEST_RUNNERS_INSTALL_DIR=/opt;
tmp="${TMPDIR:-/tmp}"
archive=https://raw.githubusercontent.com/devizer/glist/master/bin/net-test-runners.tar.gz;
cmd="(wget -O $tmp/net-test-runners.tar.gz --no-check-certificate $archive 2>/dev/null || curl -o $tmp/net-test-runners.tar.gz -kSL $archive)"
eval "$cmd" || eval "$cmd" || eval "$cmd" || rm -f $tmp/net-test-runners.tar.gz
pushd "$NET_TEST_RUNNERS_INSTALL_DIR" >/dev/null
sudo tar xzf $tmp/net-test-runners.tar.gz
cd net-test-runners 
bash link-unit-test-runners.sh 
popd >/dev/null

