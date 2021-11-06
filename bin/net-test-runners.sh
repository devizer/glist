#!/usr/bin/env bash
export NET_TEST_RUNNERS_INSTALL_DIR=/opt;
archive=https://raw.githubusercontent.com/devizer/glist/master/bin/net-test-runners.tar.gz;
cmd="(wget -O /tmp/net-test-runners.tar.gz --no-check-certificate $archive 2>/dev/null || curl -o /tmp/net-test-runners.tar.gz -kSL $archive)"
eval "$cmd" || eval "$cmd" || eval "$cmd" || rm -f /tmp/net-test-runners.tar.gz
pushd "$NET_TEST_RUNNERS_INSTALL_DIR" >/dev/null
tar xzf /tmp/net-test-runners.tar.gz
cd net-test-runners 
bash link-unit-test-runners.sh 
popd >/dev/null

