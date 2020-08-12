# Naive check runs checks once a minute to see if either of the processes exited.
# This illustrates part of the heavy lifting you need to do if you want to run
# more than one service in a container. The container exits with an error
# if it detects that either of the processes has exited.
# Otherwise it loops forever, waking up every 60 seconds

while sleep 60;
  do ps aux |grep java\ -jar\ -Xms |grep -q -v grep; process1=$?; ps aux |grep crond\ -f |grep -q -v grep; process2=$?; if [ $process1 != $process2 ]; then javaprocess=$(pidof java); kill $javaprocess; crondprocess=$(pidof crond); kill $crondprocess; exit 1; fi;
done