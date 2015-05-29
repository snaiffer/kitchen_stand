#!/bin/bash

dir_script=`dirname $0`
dir_data="$dir_script/data"
dir_libs="$dir_script/libs"
dir_data_repos="$dir_script/data_repos"
source $dir_libs/general.sh

ip_server="192.168.1.1"
name_server="server.local"

printf "Setting for autologin... "
while true; do 
  echo
  printf "\tEnter user name=" && read username && \
  grep -w $username /etc/passwd &> /dev/null
  if [[ "$?" = "0" ]]; then 
    break;
  else
    echo "Error: User with name $username isn't exist!"
  fi; 
done
sed -i "s/# autologin.*/autologin=${username}/" /etc/lxdm/lxdm.conf
check_status

printf "Setting yum repos... "
rm -Rf /etc/yum.repos.d/* && \
cp -f $dir_data_repos/forclient.repo /etc/yum.repos.d/ && \
sed -i "s/192.168.1.1/$ip_server/g" /etc/yum.repos.d/forclient.repo
yum clean all &> /dev/null && \
yum repolist &> /dev/null
check_status

printf "Setting ntp (time sync)... "
cp -f $dir_data/ntp.conf_client /etc/ntp.conf
sed -i "s/192.168.1.1/$ip_server/g" /etc/ntp.conf
service ntpd stop
ntpdate $ip_server
service ntpd start
chkconfig ntpd on
check_status

printf "Removing unnecessary packages... "
yum remove -y -q xfce4-panel xfce4-appfinder xfdesktop Thunar thunar-archive-plugin gnome-screensaver
check_status

printf "Installing necessary packages... "
yum install -y -q wmctrl 1C_Enterprise83-client-8.3.6-2014
check_status

printf "Coping autofullscreen, autostart_1c, gencalib (screen-calibrator)... "
cp -f ${dir_data}/{autofullscreen,autostart_1c,gencalib} /usr/bin/ && \
chmod +x /usr/bin/{autofullscreen,autostart_1c,gencalib}
check_status

printf "Setttings for touchscreen... "
# for old stand
#for cur_profile in `find /home/ -name .bash_profile`; do
#  echo 'xinput set-int-prop "USB Touchscreen 0dfc:0001" "Evdev Axis Calibration" 32 2235 735 875 2069' >> $cur_profile
#done
cp -f $dir_data/xorg.conf /etc/X11/
check_status

printf "Setting noscreensaver, autostart_1c, autofullscreen, autostart_sonda... "
cp -f ${dir_data}/{noscreensaver.desktop,autostart_1c.desktop,autofullscreen.desktop,autostart_sonda.desktop} /etc/xdg/autostart/ && \
chmod +x /etc/xdg/autostart/*
check_status

printf "Removing unnecessary from autostart... "
rm -f /etc/xdg/autostart/{alsa-tray.desktop,gdu-notification-daemon.desktop,gnome-keyring-daemon.desktop,nm-applet.desktop,polkit-gnome-authentication-agent-1.desktop,restorecond.desktop,spice-vdagent.desktop,user-dirs-update-gtk.desktop,vino-server.desktop,xfce-polkit-gnome-authentication-agent-1.desktop,xscreensaver.desktop,zlevel-switcher.desktop}
check_status

printf "iptables off..."
service iptables stop &> /dev/null
chkconfig iptables off &> /dev/null
check_status

printf "for DrWeb..."
yum install -y -q glibc.i686
check_status

printf "for 1c..."
echo "127.0.0.1 $(hostname)" >> /etc/hosts
echo "$ip_server $name_server" >> /etc/hosts
service srv1cv83 stop
chkconfig srv1cv83 off
check_status

printf "Coping sonda.."
cp -Rf $dir_data/sonda_client /opt/
chmod -R 777 /opt/sonda_client
cp -f $dir_data/80-futronic.rules /etc/udev/rules.d/
cp -f $dir_data/80-futronic.rules /lib/udev/rules.d/
check_status

printf "Setting for OS... "
sed -i "/pam_gnome_keyring.so/d" /etc/pam.d/lxdm
check_status

reboot_request
