FROM openjdk:8 AS build
MAINTAINER BlueEnni

WORKDIR /data

ARG url=https://www.tekx.it/downloads/
ARG version=0.981Tekxit3Server
ARG jarfile=forge-1.12.2-14.23.5.2847-universal.jar
# Set memory size
ARG memory_size=4G
ARG mounteddir=/var/lib/minecraft
ENV MOUNTEDDIR=$mounteddir
ENV URL=$url
ENV VERSION=$version

#Downloading tekxitserver.zip
RUN wget ${URL}${VERSION}.zip \
#Downloading unzip\
&& apt-get update -y && apt-get install unzip wget -y --no-install-recommends \
#unziping the package\
&& unzip ${VERSION}.zip -d /data/ \
&& mv ${VERSION}/* /data/ \
&& rmdir ${VERSION} \
&& rm ${VERSION}.zip \
#downloading the backupmod\
&& wget https://media.forgecdn.net/files/2819/669/FTBBackups-1.1.0.1.jar \
&& mv FTBBackups-1.1.0.1.jar /data/mods/ \
&& wget https://media.forgecdn.net/files/2819/670/FTBBackups-1.1.0.1-sources.jar \
&& mv FTBBackups-1.1.0.1-sources.jar /data/mods/ \
#accepting the eula\
&& touch eula.txt \
&& echo 'eula=true'>eula.txt \
#adding backupscript
&& touch backup_data_MC.sh \
\
\
&& echo "#!/bin/bash\n\
if [ \"\$(id -u)\" != \"0\" ]; then\n\
    echo \"This script must be run as root\" 1>&2\n\
    exit 1\n\
fi\n\
\n">> backup_data_MC.sh \
&& echo '######################## CONFIG START ########################\n'>> backup_data_MC.sh \
&& echo "MAINTAINERLOGIN=\"yes\"\n\
ROOTPW=\"\" # Optional, leave empty if MAINTAINERLOGIN=yes\n\
PRIORITY=\"0\" # \"-19\" is highest, \"19\" is lowest\n">> backup_data_MC.sh \
&& echo '######################### CONFIG END #########################\n'>> backup_data_MC.sh \
&& echo " \n\
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin\n\
DATE=\`date +%Y%m%d_%H%M\`\n\
TAR=\`which tar\`\n\
NICE=\`which nice\`\n\
LOGINLINE=\"-uroot -p\$ROOTPW\"\n\
DATEONLY=\`date +%Y%m%d_%H00\`\n\
DAYOLD=\`date '+%Y%m%d' -d \"\$end_date-5 days\"\`\n\
HOUROLD=\`date '+%Y%m%d_%H00' -d \"\$end_date-5 hours\"\`\n\
\n\
rm -r $MOUNTEDDIR/FULL_BACKUP_\$HOUROLD\n\
rm -r $MOUNTEDDIR/FULL_BACKUP_\$DAYOLD*\n\
\n\
function revertchanges {\n\
	rm -r $MOUNTEDDIR/FULL_BACKUP_\$DATEONLY\n\
}\n\
\n\
if [ \$MAINTAINERLOGIN == \"yes\" ] ; then\n">> backup_data_MC.sh \
	&& echo 'echo -en "Testing debian-sys-maintainer login...\\t\\t\\t"\n\
	MAINTLOGIN=`mysqladmin --defaults-file=/etc/mysql/debian.cnf ping 2>&1 | grep "Access denied"`\n\
	if [ ! -z "$MAINTLOGIN" ] ; then\n\
		echo -e "\\e[00;31m ERR: Login failed\\e[00m"\n\
		exit 1\n\
	fi\n\
	echo -e "\\e[00;32m OK\\e[00m"\n\
	LOGINLINE="--defaults-file=/etc/mysql/debian.cnf"\n\
else\n\
	echo -en "Testing root login...\\t\\t\\t\\t\\t"\n\
	MAINTLOGIN=`mysqladmin -uroot -p$ROOTPW ping 2>&1 | grep "Access denied"`\n\
	if [ ! -z "$MAINTLOGIN" ] ; then\n\
		echo -e "\\e[00;31m ERR: Login failed\\e[00m"\n\
		exit 1\n\
	fi\n\
	echo -e "\\e[00;32m OK\\e[00m"\n\
fi\n\
\n'>> backup_data_MC.sh \
&& echo "mkdir -p $MOUNTEDDIR/FULL_BACKUP_\$DATEONLY\n\
\n">> backup_data_MC.sh \
&& echo 'echo -en "Full backup...\\t\\t\\t\\t\\t\\t"\n'>> backup_data_MC.sh \
&& echo "GREPTAR=\$(\$NICE -\$PRIORITY \$TAR -zcpf $MOUNTEDDIR/FULL_BACKUP_\$DATEONLY/fullbackup.tar.gz --directory=/data/ --exclude=backups . 2>&1)\n">> backup_data_MC.sh \
&& echo 'TAREXC=$?\n\
if [ $TAREXC -eq 2 ] ; then\n\
        echo -e "\\e[00;31m FATAL ERR\\e[00m"\n\
        echo -e "\\n\\n\\n$GREPTAR"\n\
        revertchanges\n\
        exit 1\n\
fi\n\
if [ $TAREXC -eq 1 ] ; then\n\
        echo -e "\\e[00;31m WARNING:\\e[00m"\n\
        echo -e "\\n\\n\\n$GREPTAR"\n\
fi\n\
if [ $TAREXC -eq 0 ] ; then\n\
        echo -e "\\e[00;32m OK \\e[00m"\n\
fi\n\
\n\
echo -e "\\e[00;32m OK\\e[00m"\n\
echo -e "\\n\\nSuccessfully saved backup to\\ '>> backup_data_MC.sh  && echo "$MOUNTEDDIR/FULL_BACKUP_\$DATEONLY\"\n\
exit 0" >> backup_data_MC.sh \
\
\
&& chmod +x backup_data_MC.sh \
&& touch entrypoint.sh \
&& echo '#!/bin/bash\n'>> entrypoint.sh \
&& chmod +x entrypoint.sh \
&& touch kill-pid.sh \
\
\
&& echo '# Naive check runs checks once a minute to see if either of the processes exited.\n\
# This illustrates part of the heavy lifting you need to do if you want to run\n\
# more than one service in a container. The container exits with an error\n\
# if it detects that either of the processes has exited.\n\
# Otherwise it loops forever, waking up every 60 seconds\n\
\n\
while sleep 60;\n\
  do ps aux |grep java\ -jar\ -Xms |grep -q -v grep; process1=$?; ps aux |grep crond\ -f |grep -q -v grep; process2=$?; if [ $process1 != $process2 ]; then javaprocess=$(pidof java); kill $javaprocess; crondprocess=$(pidof crond); kill $crondprocess; exit 1; fi;\n\
done'>> kill-pid.sh \
\
\
&& chmod +x kill-pid.sh


FROM adoptopenjdk/openjdk8:alpine-slim AS runtime
COPY --from=build /data /data
RUN apk add --no-cache bash \
&& echo '# Add the cronjobs'>> entrypoint.sh \
&& echo 'echo '"'"'${BACKUPDENSITYCRON}/data/backup_data_MC.sh'"'"' > /etc/crontabs/root'>> entrypoint.sh \
&& echo 'echo '"'"'* * * * * /data/kill-pid.sh'"'"' >> /etc/crontabs/root'>> entrypoint.sh \
&& echo 'echo '"'"'* * * * * java -jar -Xms$MEMORYSIZE -Xmx$MEMORYSIZE $JAVAFLAGS ./${JARFILE} --nojline nogui &'"'"'>>/etc/crontabs/root'>> entrypoint.sh \
&& echo 'status=$?'>> entrypoint.sh \
&& echo 'if [ $status -ne 0 ]; then'>> entrypoint.sh \
&& echo '  echo "Failed to write into crontab: $status"'>> entrypoint.sh \
&& echo '  exit $status'>> entrypoint.sh \
&& echo 'fi'>> entrypoint.sh \
&& echo '# Start the crond process'>> entrypoint.sh \
&& echo 'crond -f'>> entrypoint.sh \
&& echo 'status=$?'>> entrypoint.sh \
&& echo 'if [ $status -ne 0 ]; then'>> entrypoint.sh \
&& echo '  echo "Failed to start crond: $status"'>> entrypoint.sh \
&& echo 'fi'>> entrypoint.sh

WORKDIR /data

ARG mounteddir=/var/lib/minecraft
ARG version=0.981Tekxit3Server
ARG jarfile=forge-1.12.2-14.23.5.2847-universal.jar
ARG memory_size=4G
ARG backupdensitycron="0 * * * * "
ARG java_flags="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=mcflags.emc.gs -Dcom.mojang.eula.agree=true -Dfml.queryResult=confirm"
ENV JAVAFLAGS=$java_flags
ENV MEMORYSIZE=$memory_size
ENV BACKUPDENSITYCRON=$backupdensitycron
ENV JARFILE=$jarfile
ENV VERSION=$version
ENV MOUNTEDDIR=$mounteddir

# Expose minecraft port
EXPOSE 25565/tcp
EXPOSE 25565/udp

# Volumes for the external data (Server, World, Config...)
VOLUME "/data"

# Entrypoint with java optimisations
ENTRYPOINT /data/entrypoint.sh