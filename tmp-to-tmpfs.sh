rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/apt/*
rm -rf /var/tmp/*
rm -rf /tmp/*

echo '

tmpfs   /tmp                tmpfs   rw     0  0
tmpfs   /var/lib/apt/lists  tmpfs   rw     0  0
tmpfs   /var/cache/apt      tmpfs   rw     0  0
tmpfs   /var/tmp            tmpfs   rw     0  0
' >> /etc/fstab

mount -t tmpfs tmpfs /tmp
mount -t tmpfs tmpfs /var/lib/apt/lists
mount -t tmpfs tmpfs /var/cache/apt
mount -t tmpfs tmpfs /var/tmp


echo '
deb http://archive.debian.org/debian/ wheezy main
deb http://archive.debian.org/debian-security/ wheezy/updates main
' > /etc/apt/sources.list

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 9D6D8F6BC857C906
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7638D0442B90D010

apt-get -o Acquire::Check-Valid-Until=false update

echo '
Acquire::Check-Valid-Until "0";
' > /etc/apt/apt.conf.d/10no--check-valid-until

echo '
APT::Get::Assume-Yes "true";
' > /etc/apt/apt.conf.d/11assume-yes

echo '
APT::Get::AllowUnauthenticated "true";
' > /etc/apt/apt.conf.d/12allow-unauth

