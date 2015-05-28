#!/bin/bash

dbname="$1"

printf "Setting /etc/crontab... "
grep -iRnH "0 0 \* \* \* root.*/etc/cron.daily$" /etc/crontab &> /dev/null
if [ "$?" != "0" ]; then
  sed -i "/cron\.daily/d" /etc/crontab
  echo "00 0 * * * root run-parts /etc/cron.daily" >> /etc/crontab
fi
echo "done."

printf "Setting autobackup... "
mkdir -p /etc/cron.daily
cp -f autobackup /etc/cron.daily/
if [[ "$dbname" != "" ]]; then 
  sed -i "s/kitchen/$dbname/g" /etc/cron.daily/autobackup
fi
echo "done."
echo
