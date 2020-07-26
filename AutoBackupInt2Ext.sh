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
  curl -s --form-string token="$app_token" --form-string user="$user_token" --form-string message="$message_form" https://api.pushover.net/1/messages.json
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
  Timestamp_message=$(echo "sync started")
  Timestamp "$Timestamp_message"
  message_form=$(echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - NOTICE - sync started")
  Pushover
  rsync -avrvi --delete --exclude 'lost+found' --progress $rsyncsource $rsyncdestination --log-file="$logdir"/"$Timestamp".log
}
#
function exit_segment ()
{
  rm -r "$lockdir"          #remove the lockdir once used
  umount "$mountpoint"
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - SUCCESS - sync completed"
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Hard Drive "$mountpoint" unmounted"
  message_form=$(echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - SUCCESS - sync completed, unplug the drive")
  Pushover
  echo "-------------------------------------------------------------------------"
  exit 0
}
#
#
####################
## import scripts ##
####################
source $HOME/.config/ScriptSettings/sync_config.sh
#
#
##################
## start script ##
##################
echo "-------------------------------------------------------------------------"
echo "$(date +%d/%m/%Y) - $(date +%H:%M:%S) - script name = $scriptname"
if mkdir "$lockdir"
then   # lock directory did not exist, but was created successfully
 grep -qs "$mount" /proc/mounts #if grep sees the mount then it will return a silent 0 if not seen a silent 1
   if [[ $? -eq 0 ]]
   then
     echo "$(date +%d/%m/%Y) - $(date +%H:%M:%S) - NOTICE - Hard Drive already mounted"
     mountpoint=$(grep "$mount" /proc/mounts | cut -c 1-9)
     echo "mountpoint is $mountpoint"
     rsync_command
     exit_segment
   else
     if [[ $? -eq 1 ]]
     then
     echo "$(date +%d/%m/%Y) - $(date +%H:%M:%S) - NOTICE - Hard Drive NOT currently mounted."
       if mount -U "$uuid" "$mount"
       then
        echo "$(date +%d/%m/%Y) - $(date +%H:%M:%S) - NOTICE - Hard Drive mounted successfully"
        rsync_command
        exit_segment
       else
        echo "$(date +%d/%m/%Y) - $(date +%H:%M:%S) - ERROR - Something went wrong with the mount..."
        message_form=$(echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - ERROR - Something went wrong with the mount...")
        Pushover
        echo "-------------------------------------------------------------------------"
        exit 1
       fi
     fi
   fi
else
  echo "$(date +%d/%m/%Y) - $(date +%H:%M:%S) - ERROR - Another instance of this script tried to run, $lockdir"
  message_form=$(echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - ERROR - Another instance of this script tried to run...")
  Pushover
  exit 1
fi
