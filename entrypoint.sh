#!/bin/bash
# Add the cronjobs
echo "${BACKUPDENSITYCRON}/data/backup_data_MC.sh" > /etc/crontabs/root
echo "* * * * * /data/kill-pid.sh" >> /etc/crontabs/root
echo "* * * * * java -jar -Xms$MEMORYSIZE -Xmx$MEMORYSIZE $JAVAFLAGS ./${JARFILE} --nojline nogui">>/etc/crontabs/root
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to write into crontab: $status"
  exit $status
fi
# Start the crond process
crond -f
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start crond: $status"
fi