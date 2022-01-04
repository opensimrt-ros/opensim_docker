apt remove openjdk-8-jre-headless --yes
DEBIAN_FRONTEND=noninteractive
ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
wget http://security.debian.org/pool/main/t/tzdata/tzdata_2019c-0+deb8u1_all.deb
dpkg -i tzdata_2019c-0+deb8u1_all.deb 

wget http://security.debian.org/pool/main/t/tzdata/tzdata-java_2019c-0+deb8u1_all.deb
dpkg -i tzdata-java_2019c-0+deb8u1_all.deb 

wget http://security.debian.org/pool/main/libj/libjpeg-turbo/libjpeg62-turbo_1.3.1-12+deb8u2_amd64.deb
dpkg -i libjpeg62-turbo_1.3.1-12+deb8u2_amd64.deb

wget http://ftp.debian.org/debian/pool/main/s/sysvinit/initscripts_2.96-7_all.deb
#I don't think we need this, so maybe just a proforma install is enough?
dpkg --force all -i initscripts_2.96-7_all.deb  

wget http://ftp.debian.org/debian/pool/main/l/lksctp-tools/libsctp1_1.0.18+dfsg-1_amd64.deb
dpkg -i libsctp1_1.0.18+dfsg-1_amd64.deb 

wget http://security.debian.org/pool/main/o/openjdk-7/openjdk-7-jre-headless_7u261-2.6.22-1~deb8u1_amd64.deb
dpkg -i openjdk-7-jre-headless_7u261-2.6.22-1~deb8u1_amd64.deb
