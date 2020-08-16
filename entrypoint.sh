#!/bin/bash
mv /data /files
# Add the cronjobs
echo "${BACKUPDENSITYCRON}/files/backup_data_MC.sh" > /etc/crontabs/root
echo "* * * * * /files/kill-pid.sh">> /etc/crontabs/root
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