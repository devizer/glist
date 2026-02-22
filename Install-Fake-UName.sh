#!/usr/bin/env bash
# url=https://raw.githubusercontent.com/devizer/glist/master/Install-Fake-UName.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash

set -eu

function get_arm_level() {
local cfile="${TMPDIR:-/tmp}/arm-level-probe"
rm -f "$cfile"
cat <<-'EOF' > "$cfile.c"
# define __ARM_LEVEL__ 0
# define __ARM_LEVEL_STRING__ ""
# define STRINGIZE(x) #x
# define STRINGIZE_VALUE_OF(x) STRINGIZE(x)
#  if defined(__ARM_ARCH)
#      define __ARM_LEVEL__ __ARM_ARCH
#      define __ARM_LEVEL_STRING__ STRINGIZE_VALUE_OF(__ARM_ARCH)
#  endif
#  if defined(__ARM_ARCH_2__) || defined(__ARM_ARCH_2) 
#      define __ARM_LEVEL__ 2
#      define __ARM_LEVEL_STRING__ "2"
#  endif
#  if defined(__ARM_ARCH_3__) || defined(__ARM_ARCH_3) 
#      define __ARM_LEVEL__ 3
#      define __ARM_LEVEL_STRING__ "3"
#  endif
#  if defined(__ARM_ARCH_3M__) || defined(__ARM_ARCH_3M) 
#      define __ARM_LEVEL__ 3
#      define __ARM_LEVEL_STRING__ "3m"
#  endif
#  if defined(__ARM_ARCH_4__) || defined(__ARM_ARCH_4) 
#      define __ARM_LEVEL__ 4
#      define __ARM_LEVEL_STRING__ "4"
#  endif
#  if defined(__ARM_ARCH_4T__) || defined(__ARM_ARCH_4T) 
#      define __ARM_LEVEL__ 4
#      define __ARM_LEVEL_STRING__ "4t"
#  endif
#  if defined(__ARM_ARCH_5__) || defined(__ARM_ARCH_5) 
#      define __ARM_LEVEL__ 5
#      define __ARM_LEVEL_STRING__ "5"
#  endif
#  if defined(__ARM_ARCH_5E__) || defined(__ARM_ARCH_5E) 
#      define __ARM_LEVEL__ 5
#      define __ARM_LEVEL_STRING__ "5e"
#  endif
#  if defined(__ARM_ARCH_5TEJ__) || defined(__ARM_ARCH_5TEJ) 
#      define __ARM_LEVEL__ 5
#      define __ARM_LEVEL_STRING__ "5tej"
#  endif
#  if defined(__ARM_ARCH_5TE__) || defined(__ARM_ARCH_5TE) 
#      define __ARM_LEVEL__ 5
#      define __ARM_LEVEL_STRING__ "5te"
#  endif
#  if defined(__ARM_ARCH_5T__) || defined(__ARM_ARCH_5T) 
#      define __ARM_LEVEL__ 5
#      define __ARM_LEVEL_STRING__ "5t"
#  endif
#  if defined(__ARM_ARCH_6__) || defined(__ARM_ARCH_6) 
#      define __ARM_LEVEL__ 6
#      define __ARM_LEVEL_STRING__ "6"
#  endif
#  if defined(__ARM_ARCH_6J__) || defined(__ARM_ARCH_6J) 
#      define __ARM_LEVEL__ 6
#      define __ARM_LEVEL_STRING__ "6j"
#  endif
#  if defined(__ARM_ARCH_6K__) || defined(__ARM_ARCH_6K) 
#      define __ARM_LEVEL__ 6
#      define __ARM_LEVEL_STRING__ "6k"
#  endif
#  if defined(__ARM_ARCH_6M__) || defined(__ARM_ARCH_6M) 
#      define __ARM_LEVEL__ 6
#      define __ARM_LEVEL_STRING__ "6m"
#  endif
#  if defined(__ARM_ARCH_6T2__) || defined(__ARM_ARCH_6T2) 
#      define __ARM_LEVEL__ 6
#      define __ARM_LEVEL_STRING__ "6t2"
#  endif
#  if defined(__ARM_ARCH_6ZK__) || defined(__ARM_ARCH_6ZK) 
#      define __ARM_LEVEL__ 6
#      define __ARM_LEVEL_STRING__ "6zk"
#  endif
#  if defined(__ARM_ARCH_6Z__) || defined(__ARM_ARCH_6Z) 
#      define __ARM_LEVEL__ 6
#      define __ARM_LEVEL_STRING__ "6z"
#  endif
#  if defined(__ARM_ARCH_7__) || defined(__ARM_ARCH_7) 
#      define __ARM_LEVEL__ 7
#      define __ARM_LEVEL_STRING__ "7"
#  endif
#  if defined(__ARM_ARCH_7A__) || defined(__ARM_ARCH_7A) 
#      define __ARM_LEVEL__ 7
#      define __ARM_LEVEL_STRING__ "7a"
#  endif
#  if defined(__ARM_ARCH_7EM__) || defined(__ARM_ARCH_7EM) 
#      define __ARM_LEVEL__ 7
#      define __ARM_LEVEL_STRING__ "7em"
#  endif
#  if defined(__ARM_ARCH_7M__) || defined(__ARM_ARCH_7M) 
#      define __ARM_LEVEL__ 7
#      define __ARM_LEVEL_STRING__ "7m"
#  endif
#  if defined(__ARM_ARCH_7R__) || defined(__ARM_ARCH_7R) 
#      define __ARM_LEVEL__ 7
#      define __ARM_LEVEL_STRING__ "7r"
#  endif
#  if defined(__ARM_ARCH_7S__) || defined(__ARM_ARCH_7S) 
#      define __ARM_LEVEL__ 7
#      define __ARM_LEVEL_STRING__ "7s"
#  endif
#  if defined(__ARM_ARCH_8A__) || defined(__ARM_ARCH_8A) 
#      define __ARM_LEVEL__ 8
#      define __ARM_LEVEL_STRING__ "8a"
#  endif
#  if defined(__ARM_ARCH_8M_BASE__) || defined(__ARM_ARCH_8M_BASE) 
#      define __ARM_LEVEL__ 8
#      define __ARM_LEVEL_STRING__ "8m baseline"
#  endif
#  if defined(__ARM_ARCH_8M_MAIN__) || defined(__ARM_ARCH_8M_MAIN) 
#      define __ARM_LEVEL__ 8
#      define __ARM_LEVEL_STRING__ "8m mainline"
#  endif
#  if defined(__ARM_ARCH_8R__) || defined(__ARM_ARCH_8R) 
#      define __ARM_LEVEL__ 8
#      define __ARM_LEVEL_STRING__ "8r"
#  endif

#include <stdio.h>
int main()
{
  printf("ARM_LEVEL_NUMERIC=%d\n", __ARM_LEVEL__);
  printf("ARM_LEVEL_STRING=%s\n", __ARM_LEVEL_STRING__);
  return 0;
}
EOF
for cc in "gcc" "clang"; do
  if [[ -z "$(command -v $cc)" ]]; then continue; fi
  rm -f $cfile
  "$cc" $cfile.c -o $cfile  1>"${TMPDIR:-/tmp}/arm-level-probe-compiler-output" 2>&1; 
  local isOk=false
  $cfile > "${TMPDIR:-/tmp}/arm-level-probe-result" 2>"${TMPDIR:-/tmp}/arm-level-probe-result-errors" && isOk=true
  if [[ "${isOk}" == "true" ]]; then break; fi
done
if [[ -s "${TMPDIR:-/tmp}/arm-level-probe-result" ]]; then 
  . "${TMPDIR:-/tmp}/arm-level-probe-result"
fi
}


# green yellow red
function say() { 
   local NC='\033[0m' Color_Green='\033[1;32m' Color_Red='\033[1;31m' Color_Yellow='\033[1;33m'; 
   local var="Color_${1:-}"
   local color="${!var}"
   shift 
   printf "${color:-}$*${NC}\n";
}

machine="$(uname -m)"; 
bit="$(getconf LONG_BIT)"
[[ "$machine" == x86_64 ]]  && [[ "$bit" == "32" ]] && machine=i686
if [[ "$machine" == aarch64 || "$machine" == arm* ]] && [[ "$bit" == "32" ]]; then
  machine=armv7l
  say Yellow "dpkg --print-architecture: [$(dpkg --print-architecture)]"
  [[ "$(dpkg --print-architecture)" == armel ]] && machine=armv5l
  
  get_arm_level
  if [[ "${ARM_LEVEL_NUMERIC:-}" == "6" ]]; then machine=armv6l; fi
fi


say Yellow "Installing FAKE UNAME for [$(uname -m)]"
say Green "Adjected machine: [${machine}]"
echo ${machine} > /etc/system-uname-m
uname="$(command -v uname)"
sudo cp "${uname}" /usr/bin/uname-bak;
script=https://raw.githubusercontent.com/devizer/glist/master/Fake-uname.sh;
cmd="(wget --no-check-certificate -O /tmp/Fake-uname.sh $script 2>/dev/null || curl -kfSL -o /tmp/Fake-uname.sh $script)"
eval "$cmd || $cmd || $cmd" && sudo cp /tmp/Fake-uname.sh /usr/bin/uname && sudo chmod +x /usr/bin/uname; echo "OK"
say Green "FAKE UNAME Result: [$(uname -m)]"
