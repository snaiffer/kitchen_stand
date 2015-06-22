#!/bin/bash

dbname_postgresql="$1"

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
if [[ "$dbname_postgresql" != "" ]]; then
  sed -i "s/kitchen/$dbname_postgresql/g" /etc/cron.daily/autobackup
fi
cp -f autobackup_sonda /etc/cron.daily/
chmod +x /etc/cron.daily/*
echo "done."
echo
