#!/usr/bin/env bash
# one-line installer:
#
# url=https://raw.githubusercontent.com/devizer/glist/master/latest-nginx/Repo-for-NGINX.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -sSL $url) | bash
#

echo 'Installing repo for latest nginx. It includes:
 nginx
 nginx-module-geoip
 nginx-module-image-filter
 nginx-module-njs
 nginx-module-perl
 nginx-module-xslt
'

# DEB: https://joshtronic.com/2018/12/17/how-to-install-the-latest-nginx-on-debian-and-ubuntu/
# RH: https://www.cyberciti.biz/faq/how-to-install-and-use-nginx-on-centos-7-rhel-7/
# mainline here is optional? http://nginx.org/packages/[mainline]/os/ver

if [ -f "/etc/debian_version" ]; then
  url=https://nginx.org/keys/nginx_signing.key
  (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -sSL $url) | sudo apt-key add -
  . /etc/os-release
  echo "
deb http://nginx.org/packages/$ID/ $(lsb_release -c -s) nginx
# deb-src http://nginx.org/packages/$ID/ $(lsb_release -c -s) nginx
" | sudo tee /etc/apt/sources.list.d/nginx.list >/dev/null

  # sudo apt update && sudo apt install nginx -y
  # sudo systemctl start nginx

elif [ -f "/etc/redhat-release" ]; then
  . /etc/os-release
  # Cut "7.6" to "7". And "7" transforms to "7" as is
  VERSION_ID=$(echo "$VERSION_ID" | cut -f1 -d".")
  echo '
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/mainline/'$ID'/'$VERSION_ID'/$basearch/
gpgcheck=0
enabled=1
' | sudo tee /etc/yum.repos.d/nginx.repo >/dev/null

  # sudo yum install -y nginx

else
  echo "ERROR: OS IS NOT SUPPORTED. Default repo will be used"
fi
