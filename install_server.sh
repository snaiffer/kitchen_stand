#!/bin/bash

dir_script=`dirname $0`
dir_data="$dir_script/data"
dir_libs="$dir_script/libs"
dir_data_repos="$dir_script/data_repos"
source $dir_libs/general.sh
postgres_pass='RH3L@redhat'

echo "Setting local repos: "
printf "\tCoping repos... "
mkdir /mnt/os /mnt/rdbms
cp -Rf $dir_data_repos/mnt/* /mnt/
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
cp -f $dir_data/ntp.conf_server /etc/ntp.conf
service ntpd restart
chkconfig ntpd on
check_status

printf "Installing postgresql packages... "
yum install -y -q postgresql-server postgresql postgresql-contrib
check_status

printf "Setting postgresql... "
change_passwd postgres $postgres_pass
chkconfig postgresql on
service postgresql initdb
sed -i "s/ident/trust/g" /var/lib/pgsql/data/pg_hba.conf
echo -e "host\tall\tall\t0.0.0.0/0\ttrust" >> /var/lib/pgsql/data/pg_hba.conf
echo -e "sepostgresql=disabled" >> /var/lib/pgsql/data/postgresql.conf
service postgresql start
check_status

printf "Installing 1C... "
yum install -y -q 1C_Enterprise83-ws* 1C_Enterprise83-server* 1C_Enterprise83-client* 1C_Enterprise83-common* 
check_status

printf "Installing other packages... "
yum install -y -q ImageMagick httpd dhcp
check_status

printf "Setting repos access via httpd,.. "
cat $dir_data/httpd.conf_append >> /etc/httpd/conf/httpd.conf
check_status

printf "Setting for OS... "
zadm security-mode off
check_status

printf "Setting for dhcpd... "
cp -f $dir_data/dhcpd.conf /etc/dhcp/
check_status

printf "iptables off... "
service iptables stop &> /dev/null
chkconfig iptables off &> /dev/null
check_status

printf "for DrWeb..."
yum install -y -q glibc.i686
check_status

printf "for 1c..."
echo "127.0.0.1 $(hostname)" >> /etc/hosts
chkconfig srv1cv83 on
check_status

printf "Coping sonda.."
cp -Rf $dir_data/sonda /opt/
chmod -R 777 /opt/sonda
cp -f $dir_data/80-futronic.rules /etc/udev/rules.d/
cp -f $dir_data/80-futronic.rules /lib/udev/rules.d/
check_status

printf "Setting noscreensaver,autostart_sonda... "
cp -f ${dir_data}/{noscreensaver.desktop,utostart_sonda.desktop} /etc/xdg/autostart/ && \
chmod +x /etc/xdg/autostart/*
check_status

printf "Creating helpfull dirs... "
mkdir /{photos,exchange}
chmod -R 777 /{photos,exchange}
check_status

printf "autostart for httpd (apache)... "
service httpd start &> /dev/null
chkconfig httpd on
check_status

printf "Setting autobackup_db... "
cd $dir_data/autobackup_db/
./init.sh
check_status

reboot_request

