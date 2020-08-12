FROM openjdk:8 AS build
MAINTAINER BlueEnni

WORKDIR /data

ARG url=https://www.tekx.it/downloads/
ARG version=0.981Tekxit3Server
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
&& echo 'eula=true'>eula.txt
#adding backupscript, entrypointscript and the kill-process script to the container
COPY backup_data_MC.sh \
entrypoint.sh \
java-start.sh \
java-cycle.sh \
kill-pid.sh ./

#creating the actual container and copying all the files in to it
FROM adoptopenjdk/openjdk8:alpine-slim AS runtime
COPY --from=build /data /data

WORKDIR /data

RUN apk add --no-cache bash \
&& chmod +x backup_data_MC.sh \
&& chmod +x entrypoint.sh \
&& chmod +x java-start.sh \
&& chmod +x java-cycle.sh \
&& chmod +x kill-pid.sh

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

# Expose minecraft port
EXPOSE 25565/tcp
EXPOSE 25565/udp

# Volumes for the external data (Server, World, Config...)
VOLUME "/data"

# Entrypoint with java optimisations
ENTRYPOINT /data/entrypoint.sh