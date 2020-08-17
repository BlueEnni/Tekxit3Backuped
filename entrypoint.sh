#!/bin/bash
#copy files to mounted folder /data
shopt -s extglob
mv /files/!(entrypoint.sh) /data
rm -R /files/!(entrypoint.sh)
#add timezone
apk add tzdata
cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
apk del tzdata
# Add the cronjobs
echo "${BACKUPDENSITYCRON}/data/backup_data_MC.sh" > /etc/crontabs/root
echo "* * * * * /data/kill-pid.sh">> /etc/crontabs/root
crond
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start crond: $status"
  exit $status
fi
# Start the crond process
java -jar -Xms$MEMORYSIZE -Xmx$MEMORYSIZE $JAVAFLAGS ./${JARFILE} --nojline nogui
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start java -jar: $status"
fi