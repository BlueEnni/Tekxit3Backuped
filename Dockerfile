FROM openjdk:8 AS build
MAINTAINER BlueEnni

WORKDIR /files

ARG url=https://www.tekx.it/downloads/
ARG version=0.981Tekxit3Server
ENV URL=$url
ENV VERSION=$version

#adding backupscript, entrypointscript, the fixed extrautils2.cfg and the kill-process script to the container
COPY backup_data_MC.sh \
entrypoint.sh \
extrautils2.cfg \
kill-pid.sh ./
#Downloading tekxitserver.zip
RUN wget ${URL}${VERSION}.zip \
#Downloading unzip\
&& apt-get update -y && apt-get install unzip wget -y --no-install-recommends \
#unziping the package\
&& unzip ${VERSION}.zip -d /files/ \
&& mv ${VERSION}/* /files/ \
&& rmdir ${VERSION} \
&& rm ${VERSION}.zip \
#downloading the backupmod\
&& wget https://media.forgecdn.net/files/2819/669/FTBBackups-1.1.0.1.jar \
&& mv FTBBackups-1.1.0.1.jar /files/mods/ \
&& wget https://media.forgecdn.net/files/2819/670/FTBBackups-1.1.0.1-sources.jar \
&& mv FTBBackups-1.1.0.1-sources.jar /files/mods/ \
#moving the fixed extrautils2.cfg into the configfolder\
&& mv extrautils2.cfg /files/config/ \
#creating a FULLBACKUPFOLDER\
&& mkdir ./FULLBACKUP \
#accepting the eula\
&& touch eula.txt \
&& echo 'eula=true'>eula.txt

#creating the actual container and copying all the files in to it
FROM adoptopenjdk/openjdk8:alpine-slim AS runtime
COPY --from=build /files /files

WORKDIR /data

RUN apk add --no-cache bash \
&& apk add --update coreutils \
&& rm -rf /var/cache/apk/* \
&& chmod +x /files/backup_data_MC.sh \
&& chmod +x /files/entrypoint.sh \
&& chmod +x /files/kill-pid.sh

ARG version=0.981Tekxit3Server
ARG jarfile=forge-1.12.2-14.23.5.2847-universal.jar
ARG memory_size=4G
ARG backupdensitycron="0 * * * * "
ARG timezone=Europe/Berlin
ARG java_flags="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=mcflags.emc.gs -Dcom.mojang.eula.agree=true -Dfml.queryResult=confirm"
ENV JAVAFLAGS=$java_flags
ENV MEMORYSIZE=$memory_size
ENV BACKUPDENSITYCRON=$backupdensitycron
ENV JARFILE=$jarfile
ENV VERSION=$version
ENV TIMEZONE=$timezone

# Expose minecraft port
EXPOSE 25565/tcp
EXPOSE 25565/udp

# Volumes for the external data (Server, World, Config...)
VOLUME "/data"

# Entrypoint with java optimisations
ENTRYPOINT /files/entrypoint.sh