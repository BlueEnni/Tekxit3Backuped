while sleep 120;
  do ps aux |grep java\ -jar\ -Xms |grep -q -v grep; process1=$?; ps aux |grep crond\ -f |grep -q -v grep; process2=$?; if [ $process1 != $process2 ]; then exit 1; fi;
done