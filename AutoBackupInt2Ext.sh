#!/usr/bin/env bash
#
# script is kept in /usr/local/bin and should be made executable with 0755 or 0766 perms
#
#
#+------------------+
#+---"Exit Codes"---+
#+------------------+
# pick from 64 - 113 (https://tldp.org/LDP/abs/html/exitcodes.html#FTN.AEN23647)
# exit 0 = Success
# exit 64 = Variable Error
# exit 65 = Sourcing file error
# exit 66 = Processing Error
# exit 67 = Required Program Missing
#
#
#+-------------------+
#+---"Set Version"---+
#+-------------------+
version="2.0"
#
#
#+------------------------+
#+---"Define Variables"---+
#+------------------------+
scriptname=`basename "$0"`      # imports the name of this script
lockname=${scriptname::-3}    # reduces the name to remove .sh
lockdir=/tmp/"$lockname"     # name of the lock dir to be used
#
#
#+------------------------+
#+---"Define Functions"---+
#+------------------------+
rsync_command ()
{
  log "script name = $scriptname"
  log "lock name will be = $lockname"
  log "lock dir will be = $lockdir"
  log "sync started"
  message_form=$(echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - NOTICE - sync started")
  pushover
#  rsync -avrvi --delete --exclude 'lost+found' --progress $rsyncsource $rsyncdestination --log-file="$loglocation"/"$timestamp".log
}
#
exit_segment ()
{
  rm -r "$lockdir"          #remove the lockdir once used
  umount "$mountpoint"
  log "SUCCESS - sync completed"
  log "Hard Drive $mountpoint unmounted"
  message_form=$(echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - SUCCESS - sync completed, unplug the drive")
  pushover
  exit 0
}
#
#
#+----------------------+
#+---"Import scripts"---+
#+----------------------+
source /home/jlivin25/.config/ScriptSettings/sync_config.sh
source /home/jlivin25/bin/standalone_scripts/helper_script.sh
#
#
#+---------------------+
#+---"Initial Setup"---+
#+---------------------+
#Grab PID
script_pid=$(echo $$)
log_deb "Script $scriptname running, PID is: $script_pid"
#display version
log_deb "Version is: $version"
#
#
#+---------------------------------------+
#+---"Check if script running already"---+
#+---------------------------------------+
check_running
#
#
#+--------------------------------------------+
#+---Check that necessary variables are set---+
#+--------------------------------------------+
JAIL_FATAL="${scriptname}"
fatal_missing_var
#
JAIL_FATAL="${lockdir}"
fatal_missing_var
#
#
#+--------------------+
#+---"Start Script"---+
#+--------------------+
grep -qs "$mount" /proc/mounts #if grep sees the mount then it will return a silent 0 if not seen a silent 1
if [[ $? -eq 0 ]]; then
  log_deb "Hard Drive already mounted"
  mountpoint=$(grep "$mount" /proc/mounts | cut -c 1-9)
  log "mountpoint is $mountpoint"
  rsync_command
  exit_segment
else
  if [[ $? -eq 1 ]]; then
    log_deb "Hard Drive NOT currently mounted."
    if mount -U "$uuid" "$mount"; then
      log "Hard Drive mounted successfully"
      rsync_command
      exit_segment
    else
      log_err "Something went wrong with the mount..."
      message_form=$(echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - ERROR - Something went wrong with the mount...")
      pushover
      exit 66
    fi
  fi
fi
exit 0
