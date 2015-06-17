#!/bin/bash

dir_script=`dirname $0`
dir_data="$dir_script/data"
dir_libs="$dir_script/libs"
dir_data_repos="$dir_script/data_repos"
source $dir_libs/general.sh
source $dir_script/settings

printf "Setting for OS... "
#setsebool -P httpd_can_network_connect 1 && \
#setsebool -P allow_ypbind 1
printf "\tselinux: permissive... "
setenforce 0 && sleep 1 && \
sed -i "s/SELINUX=enforcing/SELINUX=permissive/" /etc/selinux/config
check_status
printf "\tturn off temperature's sensors... "
sed -i "s/kernel \/vmlinuz-2.6.*/& thermal.nocrt=1/" /etc/grub.conf
check_status

printf "Setting network... "
conf_file="/etc/sysconfig/network-scripts/ifcfg-$eth"
rm -f $conf_file
cat <<-EOF > $conf_file
DEVICE="$eth"
ONBOOT="yes"
NM_CONTROLLED="no"
BOOTPROTO="static"
IPADDR="$ip_server"
PREFIX=24
EOF
service network restart &> /dev/null
check_status

echo "Setting local repos: "
printf "\tCoping repos... "
mkdir /mnt/os /mnt/rdbms &> /dev/null
cp -Rf $dir_data_repos/mnt/* /mnt/ && \
chmod -R 777 /mnt/*
check_status
printf "\tMounting and adding to autostart... "
automount='/etc/automount.sh'
cat <<-EOF > $automount
#!/bin/bash
mount -o loop /mnt/iso/os/*.iso /mnt/os
mount -o loop /mnt/iso/rdbms/*.iso /mnt/rdbms
EOF
chmod +x $automount
$automount
echo "$automount" >> /etc/rc.local
check_status
printf "\tSetting yum repos... "
rm -Rf /etc/yum.repos.d/* && \
cp -f $dir_data_repos/forserver.repo /etc/yum.repos.d/ && \
yum clean all &> /dev/null && \
yum repolist &> /dev/null
check_status

printf "Setting ntp (time sync)... "
cp -f $dir_data/ntp.conf_server /etc/ntp.conf && \
service ntpd restart &> /dev/null && \
chkconfig ntpd on &> /dev/null
check_status

printf "Installing postgresql packages... "
yum install -y -q $pkgs_postgres &> /dev/null
check_status

printf "Setting postgresql... "
change_passwd postgres $postgres_pass && \
chkconfig $service_postgresql on &> /dev/null && \
service $service_postgresql initdb &> /dev/null && \
service $service_postgresql start &> /dev/null && \
sed -i "s/ident/trust/g" $dir_data_postgresql/pg_hba.conf && \
echo -e "host\tall\tall\t127.0.0.1/32\ttrust" >> $dir_data_postgresql/pg_hba.conf && \
echo -e "host\tall\tall\t0.0.0.0/0\ttrust" >> $dir_data_postgresql/pg_hba.conf && \
# for RDBMS Zarya
# echo -e "sepostgresql=disabled" >> $dir_data_postgresql/postgresql.conf && \
service $service_postgresql restart &> /dev/null
check_status

printf "Installing 1C... "
yum install -y -q 1C_Enterprise83-ws* 1C_Enterprise83-server* 1C_Enterprise83-client* 1C_Enterprise83-common* aksusbd &> /dev/null && \
chkconfig aksusbd on
check_status

printf "Installing other packages... "
yum install -y -q ImageMagick &> /dev/null
check_status

printf "iptables off... "
service iptables stop &> /dev/null
chkconfig iptables off &> /dev/null
check_status

echo "PXE settings:"
printf "\tinstall packages... "
yum install -y -q tftp-server dhcp httpd syslinux &> /dev/null
check_status

printf "\tsetting repos access via httpd,.. "
cat $dir_data/httpd.conf_append >> /etc/httpd/conf/httpd.conf && \
service httpd restart &> /dev/null && \
chkconfig httpd on &> /dev/null
check_status

printf "\tsetting for dhcpd... "
cat <<-EOF >> /etc/dhcp/dhcpd.conf
allow booting;
allow bootp;

subnet $subnet.0 netmask 255.255.255.0 {
  range $subnet.10 $subnet.20;
  filename "pxelinux.0";
  next-server $ip_tftpserver;
}
EOF
sed -i "s/DHCPDARGS=.*/DHCPDARGS=$eth/" /etc/sysconfig/dhcpd && \
service dhcpd restart &> /dev/null && \
# check dhcpd
netstat -an | fgrep -w 67 &> /dev/null && \
chkconfig dhcpd on &> /dev/null
check_status

printf "\tsetting for tftp... "
sed -i "s/disable.*/disable\t\t\t\= no/" /etc/xinetd.d/tftp &> /dev/null && \
service xinetd restart &> /dev/null && \
# check tftp
sleep 1 && netstat -an | fgrep -w 69 &> /dev/null
check_status

printf "\tsetting simple kernel (for first boot)... "
tftpboot='/var/lib/tftpboot'
cp -f /usr/share/syslinux/pxelinux.0 $tftpboot/
cp -f /usr/share/syslinux/menu.c32 $tftpboot/

mkdir $tftpboot/rassvet/
cp -f /mnt/os/images/pxeboot/{vmlinuz,initrd.img} $tftpboot/rassvet/

mkdir $tftpboot/pxelinux.cfg
cat <<-EOF > $tftpboot/pxelinux.cfg/default
# Меню, которое закачали
default menu.c32

# Заголовок и время на выбор пункта меню
menu title PXE Network Boot Menu
prompt 0
timeout 1   # seconds for making choose

# Первый пункт меню – загрузка с HD
#label Boot from first hard disk
#localboot 0x80

LABEL Rassvet
kernel rassvet/vmlinuz
append initrd=rassvet/initrd.img
EOF
# PXE end

printf "for DrWeb..."
yum install -y -q glibc.i686 &> /dev/null
check_status

printf "for 1c..."
echo "127.0.0.1 $(hostname)" >> /etc/hosts
chkconfig srv1cv83 on
check_status

#printf "Coping sonda.."
#cp -Rf $dir_data/sonda /opt/
#chmod -R 777 /opt/sonda
#cp -f $dir_data/80-futronic.rules /etc/udev/rules.d/
#cp -f $dir_data/80-futronic.rules /lib/udev/rules.d/
#check_status
printf "Installing sonda.."
#rpm -i $dir_data/sonda/idSonda-1.0-1.x86_64.rpm &> /dev/null && \
#cp -Rf $dir_data/sonda/*.ini /opt/sonda && \
yum install -y -q idSonda-* &> /dev/null &&\
chmod -R 777 /opt/sonda
check_status

printf "Setting noscreensaver,autostart_sonda_server,autostart_ras... "
cp -f ${dir_data}/{noscreensaver.desktop,autostart_sonda_server.desktop,autostart_ras.desktop} /etc/xdg/autostart/ && \
chmod +x /etc/xdg/autostart/*
check_status

printf "Creating helpfull dirs... "
mkdir /{photos,exchange}
chmod -R 777 /{photos,exchange}
check_status

printf "Setting autobackup_db... "
cd $dir_data/autobackup_db/
./init.sh
check_status

reboot_request

