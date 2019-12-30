#!/bin/bash
#
# script is kept in /usr/local/bin and should be made executable with 0755 or 0766 perms
#
#
########################
## Define "Variables" ##
########################
scriptname=`basename "$0"`      # imports the name of this script
lockname=${scriptname::-3}    # reduces the name to remove .sh
lockdir=/tmp/$lockname.lock     # name of the lock dir to be used
#
#
########################
## Define "Functions" ##
########################
function Timestamp ()
{
  echo "$(date +%d/%m/%Y) - $(date +%H:%M:%S) - $1"
}
#
function Pushover ()
{
  curl -s --form-string "token=$(app_token)"   --form-string "user=$(user_token)" --form-string "message=$(message_form)" https://api.pushover.net/1/messages.json
}
#
function rsync_command ()
{
  Timestamp_message=$(echo "script name = $scriptname")
  Timestamp "$Timestamp_message"
  Timestamp_message=$(echo "lock name will be = $lockname")
  Timestamp "$Timestamp_message"
  Timestamp_message=$(echo "lock dir will be = $lockdir")
  Timestamp "$Timestamp_message"
  Timestamp_message=$(echo "lock name will be = $lockname")
  Timestamp "$Timestamp_message"
  Timestamp_message=$(echo "sync started")
  Timestamp "$Timestamp_message"
  message_form=$(echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - sync started")
  rsync -avrvi --delete --exclude 'lost+found' --progress $rsyncsource $rsyncdestination --log-file="$logdir"/"$stamp".log
  Timestamp_message=$(echo "sync completed")
  Timestamp "$Timestamp_message"
}
#
#
####################
## import scripts ##
####################
source "$scriptlocation"/config.sh
#
#
##################
## start script ##
##################
(
echo "-------------------------------------------------------------------------"
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - script name = $scriptname"
if mkdir "$lockdir"
 then   # directory did not exist, but was created successfully
  # echo >&2 "`date +%d/%m/%Y` - `date +%H:%M:%S` - successfully acquired lock: $lockdir"
  # continue script
  touch "$HOME/bin/scriptlogs/$lockname.log"
  grep -qs "$mount" /proc/mounts; #if grep sees the mount then it will return a silent 0 if not seen a silent 1
  if [ $? -eq 0 ];
    then
    echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Hard Drive already mounted"
    mountpoint=$(grep "$mount" /proc/mounts | cut -c 1-9)
    echo "mountpoint is $mountpoint"
    rsync_command
    if command ; then
      echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - sync completed"
      message_form=$(echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - sync completed")
      Pushover
      rm -r "$lockdir"          #remove the lockdir once used
      umount "$mountpoint"
      echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Hard Drive $mountpoint unmounted"
      echo "-------------------------------------------------------------------------"
      exit 0 #statements
    else
       exit 1
    fi
    echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - sync completed"
    message_form=$(echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - sync completed")
    Pushover
    rm -r "$lockdir"          #remove the lockdir once used
    umount "$mountpoint"
    echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Hard Drive  $mountpoint unmounted"
    echo "-------------------------------------------------------------------------"
    exit 0
###
  else
    if [ $? -eq 1 ];
      then
      echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Hard Drive not currently mounted."
      mount -U "$uuid" "$mount"
      echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Hard Drive mounted sucessfully"
      rsync_command
      rm -r "$lockdir"          #remove the lockdir once used
      umount "$mount"
      echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Hard Drive $mount unmounted"
      echo "-------------------------------------------------------------------------"
      exit 0
###
    else
    echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Something went wrong with the mount..."
    echo "-------------------------------------------------------------------------"
    exit 1
    fi
  fi
  else
    # echo >&2 "`date +%d/%m/%Y` - `date +%H:%M:%S` - Another instance of this script tried to run, $lockdir"
    echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Another instance of this script tried to run, $lockdir"
    rm -r "$lockdir"
    exit 2
    echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - $?"
fi
echo "exit $?"
) >> "$loglocation"/"$lockname".log 2>&1 &
