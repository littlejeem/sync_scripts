#!/usr/bin/env bash
#
# script is kept in /usr/local/bin and should be made executable with 0755 or 0766 perms
#
#
#+--------------------------------------+
#+---"Exit Codes & Logging Verbosity"---+
#+--------------------------------------+
# pick from 64 - 113 (https://tldp.org/LDP/abs/html/exitcodes.html#FTN.AEN23647)
# exit 0 = Success
# exit 64 = Variable Error
# exit 65 = Sourcing file/folder error
# exit 66 = Processing Error
# exit 67 = Required Program Missing

#verbosity levels
#silent_lvl=0
#crt_lvl=1
#err_lvl=2
#wrn_lvl=3
#ntf_lvl=4
#inf_lvl=5
#dbg_lvl=6


#+-------------------+
#+---"Set Version"---+
#+-------------------+
version="3.0"


#+------------------------+
#+---"Define Variables"---+
#+------------------------+
scriptname=`basename "$0"`      # imports the name of this script
lockname=${scriptname::-3}    # reduces the name to remove .sh
lockdir=/tmp/"$lockname"     # name of the lock dir to be used
#set default logging level
verbosity=3


#+----------------------+
#+---"Import scripts"---+
#+----------------------+
source /usr/local/bin/config.sh
source /usr/local/bin/helper_script.sh


#+---------------------+
#+---"Initial Setup"---+
#+---------------------+
#Grab PID
script_pid=$(echo $$)
edebug "Script $scriptname running, PID is: $script_pid"
#display version
edebug "Version is: $version"


#+------------------------+
#+--- Define Functions ---+
#+------------------------+
rsync_command ()
{
  edebug "script name = $scriptname"
  edebug "lock name will be = $lockname"
  edebug "lock dir will be = $lockdir"
  edebug "sync started"
  message_form=$(echo "NOTICE - sync started")
  pushover > /dev/null
  if [[ $dry_run -eq 1 ]]; then
    edebug "dry-run enabled, calling rsync with dry-run flag"
    rsync --dry-run -avrvi --delete --exclude 'lost+found' --progress $rsyncsource $rsyncdestination --log-file="$loglocation"/"$timestamp".log
  else
    rsync -avrvi --delete --exclude 'lost+found' --progress $rsyncsource $rsyncdestination --log-file="$loglocation"/"$timestamp".log
  fi
}

exit_segment ()
{
  umount /dev/disk/by-uuid/"$uuid"
  enotify "SUCCESS - sync completed"
  edebug "Hard Drive $mountpoint unmounted"
  message_form=$(echo "SUCCESS - sync completed, unplug the drive")
  pushover > /dev/null
  rm -r "$lockdir"          #remove the lockdir once used
  clean_exit
}

clean_ctrlc () {
  let ctrlc_count++
  echo
  if [[ $ctrlc_count == 1 ]]; then
    echo "Quit command detected, are you sure?"
  elif [[ $ctrlc_count == 2 ]]; then
    echo "...once more and the script will exit..."
  else
    clean_exit
  fi
}

clean_exit () {
  edebug "Exiting script gracefully"
  rm -r /tmp/"$lockname"
  exit 0
}

helpFunction () {
   echo ""
   echo "Usage: $0"
   echo "Usage: $0 -dV selects dry-run with verbose level logging"
   echo -e "\t-d Use this flag to specify dry run, no files will be transferred, useful in conjunction with -V or -G "
   echo -e "\t-s Override set verbosity to specify silent log level"
   echo -e "\t-V Override set verbosity to specify verbose log level"
   echo -e "\t-G Override set verbosity to specify Debug log level"
   if [ -d "/tmp/$lockname" ]; then
     edebug "removing lock directory"
     rm -r "/tmp/$lockname"
   else
     edebug "problem removing lock directory"
   fi
   exit 1 # Exit script after printing help
}


#+------------------------+
#+---"Get User Options"---+
#+------------------------+
OPTIND=1
while getopts ":dsVGh:" opt
do
    case "${opt}" in
      d) dry_run="1"
      edebug "-d specified: dry run initiated";;
      s) verbosity=$silent_lvl
      edebug "-s specified: Silent mode";;
      V) verbosity=$inf_lvl
      edebug "-V specified: Verbose mode";;
      G) verbosity=$dbg_lvl
      edebug "-G specified: Debug mode";;
      h) helpFunction;;
      ?) helpFunction;;
    esac
done
shift $((OPTIND -1))


#+---------------------+
#+---"Trap & ctrl-c"---+
#+---------------------+
trap clean_ctrlc SIGINT
trap clean_exit SIGTERM
ctrlc_count=0


#+---------------------------------------+
#+---"Check if script running already"---+
#+---------------------------------------+
check_running


#+----------------------+
#+---"Script Started"---+
#+----------------------+
# At this point the script is set up and all necessary conditions met so lets log this
esilent "$lockname script started"


#+--------------------------------------------+
#+---Check that necessary variables are set---+
#+--------------------------------------------+
edebug "Checking necessary variables are set..."
JAIL_FATAL="${scriptname}"
fatal_missing_var

JAIL_FATAL="${lockdir}"
fatal_missing_var

JAIL_FATAL="${rsyncsource}"
fatal_missing_var

JAIL_FATAL="${rsyncdestination}"
fatal_missing_var

edebug "...necessary variables are set"


#+--------------------+
#+---"Start Script"---+
#+--------------------+
grep -qs "$mount" /proc/mounts #if grep sees the mount then it will return a silent 0 if not seen a silent 1
if [[ $? -eq 0 ]]; then
  edebug "Hard Drive already mounted"
  mountpoint=$(grep "$mount" /proc/mounts | cut -d ' ' -f 1)
  edebug "mountpoint is $mountpoint"
  rsync_command
  exit_segment
else
  if [[ $? -eq 1 ]]; then
    edebug "Hard Drive NOT currently mounted."
    if mount -U "$uuid" "$mount"; then
      edebug "Hard Drive mounted successfully"
      rsync_command
      exit_segment
    else
      eerror "Something went wrong with the mount..."
      message_form=$(echo "ERROR - Something went wrong with the mount...")
      pushover > /dev/null
      exit 66
    fi
  fi
fi
esilent "$lockname script finished"
clean_exit
