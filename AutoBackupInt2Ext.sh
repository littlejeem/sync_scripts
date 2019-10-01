#!/bin/bash
#
## script is kept in /usr/local/bin and should be made executable with 0755 or 0766 perms
scriptname=`basename "$0"`      # imports the name of this script
lockname=${scriptname::-3}    # reduces the name to remove .sh
lockdir=/tmp/$lockname.lock     # name of the lock dir to be used
sleeptime=30                    # dfines how long should the sleep period be, not necessary once script working, default is seconds, append with 'm' if wanting minutes
label=Seagate_Ext
mount=/dev/sde1
mountdir=/media/$label
scriptlocation=/home/jlivin25/bin/myscripts             # not yet in use, want to replace path in script with this variable
loglocation=/home/jlivin25/bin/myscripts/scriptlogs     # not yet in use, want to replace path in script with this variable
rsyncsource=/media/Data_1/
rsyncdestination=/media/Seagate_Ext/Backups/
(
echo "-------------------------------------------------------------------------"
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - script name = "$scriptname
#wait $sleeptime
#sleep $sleeptime
if mkdir "$lockdir"
 then   # directory did not exist, but was created successfully
        # echo >&2 "`date +%d/%m/%Y` - `date +%H:%M:%S` - successfully acquired lock: $lockdir"
        # continue script
        cd /home/jlivin25/bin/myscripts
        touch /home/jlivin25/bin/myscripts/scriptlogs/$lockname.log
                #try this http://unix.stackexchange.com/questions/38870/how-to-check-if-a-filesystem-is-mounted-with-a-script
                        grep -qs "$mount" /proc/mounts; #if grep sees the mount then it will return a silent 0 if not seen a silent 1
			if [ $? -eq 0 ];
                         then
                         echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Hard Drive already mounted"
                         echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - lock name will be = "$lockname
                         echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - lockdir will be = "$lockdir
			 echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - sync started"
                         rsync -avrv --delete --exclude 'lost+found' --progress $rsyncsource $rsyncdestination
                         echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - sync completed"
                         rm -r $lockdir          #remove the lockdir once used
                         umount $mount
                         echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Hard Drive  $mount unmounted"
                         echo "-------------------------------------------------------------------------"
			 exit 0
			 ###
			else
  				if [ $? -eq 1 ];
				   then
				   echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Hard Drive not currently mounted."
                        	   mount "$mount" "$mountdir"
				   echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Hard Drive mounted sucessfully"
				   echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - script name = "$scriptname
        			   echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - lock name will be = "$lockname
        			   echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - lockdir will be = "$lockdir
        			   echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - starting $sleeptime count to allow drive to mount"
        			   #sleep $sleeptime
				   rsync -avrv --delete --exclude 'lost+found' --progress $rsyncsource $rsyncdestination
        			   echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - sync completed"
        			   rm -r $lockdir          #remove the lockdir once used
        			   umount $mount
				   echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Hard Drive $mount unmounted"
       				   echo "-------------------------------------------------------------------------"
				   exit 0
				   ###
				   else
 				   echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Something went wrong with the mount..."
				   echo "-------------------------------------------------------------------------"
  				exit 0
				fi
			fi
else
        # echo >&2 "`date +%d/%m/%Y` - `date +%H:%M:%S` - Another instance of this script tried to run, $lockdir"
        echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Another instance of this script tried to run, $lockdir"
        rm -r $lockdir
        exit 2
        echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - $?"
 fi
echo "exit $?"
) >> /home/jlivin25/bin/myscripts/scriptlogs/$lockname.log 2>&1 &
