#!/bin/bash

dir_script=`dirname $0`
dir_data="$dir_script/data"
dir_libs="$dir_script/libs"
dir_data_repos="$dir_script/data_repos"
source $dir_libs/general.sh
source $dir_script/settings

echo "Setting for OS... "
printf "\tturn off pam_gnome_keyring: for autologin... "
sed -i "/pam_gnome_keyring.so/d" /etc/pam.d/lxdm
check_status
printf "\tselinux: permissive... "
setenforce 0 && sleep 1 && \
sed -i "s/SELINUX=enforcing/SELINUX=permissive/" /etc/selinux/config
check_status
printf "\tturn off temperature's sensors... "
sed -i "s/kernel \/vmlinuz-2.6.*/& thermal.nocrt=1/" /etc/grub.conf
check_status

printf "Setting for autologin... "
while true; do
  echo && printf "\tEnter user name=" && read username && \
  grep -w $username /etc/passwd &> /dev/null
  if [[ "$?" = "0" ]]; then
    break;
  else
    echo "Error: User with name $username isn't exist!"
  fi;
done
sed -i "s/# autologin.*/autologin=${username}/" /etc/lxdm/lxdm.conf
check_status

printf "Setting network... "
conf_file_path="/etc/sysconfig/network-scripts"
conf_file="/etc/sysconfig/network-scripts/ifcfg-$eth"
grep HWADDR $conf_file > $conf_file_path/hwaddr
mv $conf_file $conf_file_path/backup_ifcfg-$eth
cat <<-EOF > $conf_file
DEVICE=$eth
BOOTPROTO=dhcp
ONBOOT=yes
NM_CONTROLLED=no
EOF
cat $conf_file_path/hwaddr >> $conf_file
service network restart &> /dev/null
check_status

printf "Setting yum repos... "
rm -Rf /etc/yum.repos.d/* &> /dev/null && \
cp -f $dir_data_repos/forclient.repo /etc/yum.repos.d/ &> /dev/null && \
sed -i "s/192.168.1.1/$ip_server/g" /etc/yum.repos.d/forclient.repo &> /dev/null && \
yum clean all &> /dev/null && \
yum repolist &> /dev/null
check_status

printf "Setting ntp (time sync)... "
cp -f $dir_data/ntp.conf_client /etc/ntp.conf &> /dev/null && \
sed -i "s/192.168.1.1/$ip_server/g" /etc/ntp.conf &> /dev/null && \
service ntpd stop &> /dev/null && \
ntpdate $ip_server &> /dev/null && \
service ntpd start &> /dev/null && \
chkconfig ntpd on &> /dev/null
check_status

printf "Removing unnecessary packages... "
yum remove -y -q xfce4-panel xfce4-appfinder xfdesktop Thunar thunar-archive-plugin gnome-screensaver &> /dev/null
check_status

printf "Installing necessary packages... "
yum install -y -q wmctrl 1C_Enterprise83-client* &> /dev/null
check_status

printf "Coping autofullscreen, autostart_1c, gencalib (screen-calibrator)... "
cp -f ${dir_data}/{autofullscreen,autostart_1c,gencalib} /usr/bin/ && \
chmod +x /usr/bin/{autofullscreen,autostart_1c,gencalib} && \
sed -i "s/kitchen/$dbname_1C/" /usr/bin/autostart_1c
check_status

printf "Setttings for touchscreen... "
# for old stand
#for cur_profile in `find /home/ -name .bash_profile`; do
#  echo 'xinput set-int-prop "USB Touchscreen 0dfc:0001" "Evdev Axis Calibration" 32 2235 735 875 2069' >> $cur_profile
#done
cp -f $dir_data/xorg.conf /etc/X11/
check_status

printf "Setting noscreensaver, autostart_1c, autofullscreen, autostart_sonda_client... "
cp -f ${dir_data}/{noscreensaver.desktop,autostart_1c.desktop,autofullscreen.desktop,autostart_sonda_client.desktop} /etc/xdg/autostart/ && \
chmod +x /etc/xdg/autostart/*
check_status

printf "Removing unnecessary from autostart... "
rm -f /etc/xdg/autostart/{alsa-tray.desktop,gdu-notification-daemon.desktop,gnome-keyring-daemon.desktop,nm-applet.desktop,polkit-gnome-authentication-agent-1.desktop,restorecond.desktop,spice-vdagent.desktop,user-dirs-update-gtk.desktop,vino-server.desktop,xfce-polkit-gnome-authentication-agent-1.desktop,xscreensaver.desktop,zlevel-switcher.desktop}
check_status

printf "iptables off... "
service iptables stop &> /dev/null && \
chkconfig iptables off &> /dev/null
check_status

printf "for DrWeb... "
yum install -y -q glibc.i686 &> /dev/null
check_status

printf "for 1c... "
echo "127.0.0.1 $(hostname)" >> /etc/hosts && \
echo "$ip_server $name_server" >> /etc/hosts && \
service srv1cv83 stop &> /dev/null && \
chkconfig srv1cv83 off &> /dev/null
check_status

#printf "Coping sonda.."
#cp -Rf $dir_data/sonda_client /opt/
#chmod -R 777 /opt/sonda_client
#cp -f $dir_data/80-futronic.rules /etc/udev/rules.d/
#cp -f $dir_data/80-futronic.rules /lib/udev/rules.d/
#check_status
printf "Installing sonda... "
#rpm -i $dir_data/sonda/idTerminal-1.0-1.x86_64.rpm &> /dev/null && \
#cp -Rf $dir_data/sonda/*.ini /opt/sonda_client/ && \
yum install -y -q idTerminal* &> /dev/null && \
chmod -R 777 /opt/sonda_client && \
sed -i "s/address.*/address=$name_server/" /opt/sonda_client/terminal.ini
check_status

reboot_request
