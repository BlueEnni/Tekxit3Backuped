#!/bin/bash
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

######################## CONFIG START ########################
MAINTAINERLOGIN="yes"
ROOTPW="" # Optional, leave empty if MAINTAINERLOGIN=yes
PRIORITY="0" # "-19" is highest, "19" is lowest
######################### CONFIG END #########################

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DATE=`date +%Y%m%d_%H%M`
TAR=`which tar`
NICE=`which nice`
LOGINLINE="-uroot -p$ROOTPW"
DATEONLY=`date +%Y%m%d_%H00`
DAYOLD=`date '+%Y%m%d' -d "$end_date-5 days"`
HOUROLD=`date '+%Y%m%d_%H00' -d "$end_date-5 hours"`

rm -r /files/minecraft/FULL_BACKUP_$HOUROLD
rm -r /files/minecraft/FULL_BACKUP_$DAYOLD*

function revertchanges {
	rm -r /files/minecraft/FULL_BACKUP_$DATEONLY
}

if [ $MAINTAINERLOGIN == "yes" ] ; then
	echo -en "Testing debian-sys-maintainer login...\t\t\t"
	MAINTLOGIN=`mysqladmin --defaults-file=/etc/mysql/debian.cnf ping 2>&1 | grep "Access denied"`
	if [ ! -z "$MAINTLOGIN" ] ; then
		echo -e "\e[00;31m ERR: Login failed\e[00m"
		exit 1
	fi
	echo -e "\e[00;32m OK\e[00m"
	LOGINLINE="--defaults-file=/etc/mysql/debian.cnf"
else
	echo -en "Testing root login...\t\t\t\t\t"
	MAINTLOGIN=`mysqladmin -uroot -p$ROOTPW ping 2>&1 | grep "Access denied"`
	if [ ! -z "$MAINTLOGIN" ] ; then
		echo -e "\e[00;31m ERR: Login failed\e[00m"
		exit 1
	fi
	echo -e "\e[00;32m OK\e[00m"
fi

mkdir -p /files/minecraft/FULL_BACKUP_$DATEONLY

echo -en "Full backup...\t\t\t\t\t\t"
GREPTAR=$($NICE -$PRIORITY $TAR -zcpf /files/minecraft/FULL_BACKUP_$DATEONLY/fullbackup.tar.gz --directory=/files/ --exclude=backups . 2>&1)
TAREXC=$?
if [ $TAREXC -eq 2 ] ; then
        echo -e "\e[00;31m FATAL ERR\e[00m"
        echo -e "\n\n\n$GREPTAR"
        revertchanges
        exit 1
fi
if [ $TAREXC -eq 1 ] ; then
        echo -e "\e[00;31m WARNING:\e[00m"
        echo -e "\n\n\n$GREPTAR"
fi
if [ $TAREXC -eq 0 ] ; then
        echo -e "\e[00;32m OK \e[00m"
fi

echo -e "\e[00;32m OK\e[00m"
echo -e "\n\nSuccessfully saved backup to /files/minecraft/FULL_BACKUP_$DATEONLY"
exit 0
