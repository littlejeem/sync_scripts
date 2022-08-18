#!/usr/bin/env bash
#
#######################################################################################
### "Script is designed to sync content from local source to usb drive destination" ###
### "Requires a working udev rule and a systemd service to run"                     ###
### "Best to place in or symlink (ln -s filepath linkname) /usr/local/bin"          ###
#######################################################################################
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
#
#verbosity levels
#silent_lvl=0
#crt_lvl=1
#err_lvl=2
#wrn_lvl=3
#ntf_lvl=4
#inf_lvl=5
#dbg_lvl=6
#
#
#+----------------------+
#+---"Check for Root"---+
#+----------------------+
#only needed if root privaleges necessary, enable
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 66
fi
#
#
#+-----------------------+
#+---"Set script name"---+
#+-----------------------+
# imports the name of this script
# failure to to set this as lockname will result in check_running failing and 'hung' script
# manually set this if being run as child from another script otherwise will inherit name of calling/parent script
scriptlong=`basename "$0"`
lockname=${scriptlong::-3} # reduces the name to remove .sh
#
#
#+---------------------+
#+---"Set Variables"---+
#+---------------------+
#set default logging level, failure to set this will cause a 'unary operator expected' error
#set default logging level, remember at level 3 and lower, only esilent messages show, best to include an override in getopts
verbosity=3
version="0.3" #
script_pid=$(echo $$)
pushover_title="USB Sync"
#
#
#+--------------------------+
#+---Source helper script---+
#+--------------------------+
source /usr/local/bin/helper_script.sh
#
#
#+---------------------------------------+
#+---"check if script already running"---+
#+---------------------------------------+
check_running
#
#
#+-------------------+
#+---Set functions---+
#+-------------------+
helpFunction () {
   echo ""
   echo "Usage: $0 $scriptlong"
   echo "Usage: $0 -dV selects dry-run with verbose level logging"
   echo -e "\t-d Use this flag to specify dry run, no files will be converted, useful in conjunction with -V or -G "
   echo -e "\t Running the script with no flags causes default behaviour with logging level set via 'verbosity' variable"
   echo -e "\t-S Override set verbosity to specify silent log level"
   echo -e "\t-V Override set verbosity to specify Verbose log level"
   echo -e "\t-G Override set verbosity to specify Debug log level"
   echo -e "\t-h Use this flag for help"
   if [ -d "/tmp/$lockname" ]; then
     edebug "removing lock directory"
     rm -r "/tmp/$lockname"
   else
     edebug "problem removing lock directory"
   fi
   exit 65 # Exit script after printing help
}
#
#
#must pass in $section variable for this to work
rsync_command () {
if [[ "$section" -eq 1 ]]; then
  edebug "$section sync SELECTED, sync started"
  #set up source from seprate references
  edebug "$section"
  section_source="${section}"_source
  edebug "$section_source"
  source=$(echo "${!section_source}")
  edebug "$source"
  #set up destination from seperate references
  section_destination="${section}"_destination
  edebug "$section_destination"
  destination=$(echo "${!section_destination}")
  edebug "$destination"
  if [[ "$dry_run" -eq 1 ]]; then
    enotify "Rsync dry-run selected, running now"
    rsync --dry-run --remove-source-files --prune-empty-dirs $rsync_vzrc "$source" "$destination"
    edebug "$section sync finished"
  else
    rsync --remove-source-files --prune-empty-dirs $rsync_vzrc "$source" "$destination"
    if [[ $? -eq 0 ]]; then
      edebug "section: $section rsync completed successfully"
    else
      edebug "Section: $section produced an error: $?"
    fi
    edebug "$section sync finished"
  fi
else
  enotify "$section sync DESELECTED, no sync"
fi
}
#
check_space () {
  #get info in bytes about source folder
  source_size_du=$(du /mnt/usbstorage)
  edebug "Source folder size from du is: $source_size_du"
  source_size_bytes=$(echo $source_size_du | cut -d ' ' -f 1)
  edebug "Source folder size in bytes is: $source_size_bytes"
  #get info in human readable format from du
  source_size_du_human=$(du -sh /mnt/usbstorage)
  edebug "Source folder size from du is: $source_size_du_human"
  source_size_human=$(echo $source_size_du_human | cut -d ' ' -f 1)
  edebug "Source folder size is: $source_size_human"
  #get info on destination drive capacity
  drive_size_bytes=$(lsblk -b --output SIZE -n -d $mountpoint)
  edebug "Destination drive size in bytes is: $source_size_bytes"
  #now test
  if [[ $drive_size_bytes -le $source_size_bytes ]]; then
    #DRIVE too SMALL unmount it
    umount "$mountpoint"
    if [[ $? -eq 0 ]]; then
      edebug "Drive unmounted"
    else
      ecrit "FAILURE - umount returned error: $?"
      exit 66
    fi
    #notify user
    eerror "Drive size is to small, have you checked its blank/large enough?"
    message_form="ERROR: Drive size is to small to fit ($source_size_human) downloaded media on, unplug and check its blank"
    pushover
    #start script exit
    rm -r /tmp/"$lockname"
    if [[ $? -ne 0 ]]; then
        eerror "error removing lockdirectory"
        exit 65
    else
        enotify "successfully removed lockdirectory"
    fi
    esilent "$lockname completed"
    exit 66
  else
    #ALL OK, CARRY ON
    edebug "Drive capacity large enough to sync media"
  fi
}
#
exit_segment () {
umount "$mountpoint"
if [[ $? -eq 0 ]]; then
  enotify "SUCCESS - sync completed"
  edebug "USB Drive $mountpoint unmounted"
  message_form=$(echo "SUCCESS - Sync completed, unplug the drive, your goodies are ready!")
  edebug "Message_form would be: $message_form"
  pushover
else
  ecrit "FAILURE - umount returned error: $?"
  exit 66
fi
}
#
#
#+------------------------+
#+---"Get User Options"---+
#+------------------------+
OPTIND=1
while getopts ":dSVGHh:" opt
do
    case "${opt}" in
        d) dry_run="1"
        edebug "-d specified: dry run initiated";;
        S) verbosity=$silent_lvl
        edebug "-S specified: Silent mode";;
        V) verbosity=$inf_lvl
        edebug "-V specified: Verbose mode";;
        G) verbosity=$dbg_lvl
        edebug "-G specified: Debug mode";;
#Example for extra options
#        d) drive_install=${OPTARG}
#        edebug "-d specified: alternative drive being used";;
        H) helpFunction;;
        h) helpFunction;;
        ?) helpFunction;;
    esac
done
shift $((OPTIND -1))
#
#
#+----------------------+
#+---"Script Started"---+
#+----------------------+
# At this point the script is set up and all necessary conditions met so lets log this
esilent "$lockname started"
#
#
#+-------------------------------+
#+---Configure GETOPTS options---+
#+-------------------------------+
#e.g for a drive option
#if [[ $drive_install = "" ]]; then
#  drive_number="sr0"
#  edebug "no alternative drive specified, using default: $drive_number as drive install"
#else
#  drive_number=$(echo $drive_install)
#  edebug "alternative drive specified, using: $drive_number as drive install"
#fi
#edebug "GETOPTS options set"
#
#
#+--------------------------+
#+---"Source config file"---+
#+--------------------------+
config_file="/usr/local/bin/config.sh"
source $config_file
#
#
#+--------------------------------------+
#+---"Display some info about script"---+
#+--------------------------------------+
edebug "Version of $scriptlong is: $version"
edebug "PID is $script_pid"
#
#
#+-------------------+
#+---Set up script---+
#+-------------------+
#Get environmental info
edebug "INVOCATION_ID is set as: $INVOCATION_ID"
edebug "EUID is set as: $EUID"
edebug "PATH is: $PATH"
#
#
#+--------------------------------------------+
#+---Check that necessary variables are set---+
#+--------------------------------------------+
JAIL_FATAL="${lockname}"
fatal_missing_var
#
JAIL_FATAL="${usb_MUSIC}"
fatal_missing_var
#
JAIL_FATAL="${usb_TV}"
fatal_missing_var
#
JAIL_FATAL="${usb_MOVIES}"
fatal_missing_var
#
JAIL_FATAL="${usb_AUDIOBOOKS}"
fatal_missing_var
#
JAIL_FATAL="${usb_EBOOKS}"
fatal_missing_var
#
JAIL_FATAL="${usb_transfer_mount}"
fatal_missing_var
#
JAIL_FATAL="${usb_uuid}"
fatal_missing_var
#
JAIL_FATAL="${usb_MUSIC_source}"
fatal_missing_var
#
JAIL_FATAL="${usb_MUSIC_destination}"
fatal_missing_var
#
JAIL_FATAL="${usb_TV_source}"
fatal_missing_var
#
JAIL_FATAL="${usb_TV_destination}"
fatal_missing_var
#
JAIL_FATAL="${usb_MOVIES_source}"
fatal_missing_var
#
JAIL_FATAL="${usb_MOVIES_destination}"
fatal_missing_var
#
JAIL_FATAL="${usb_AUDIOBOOKS_source}"
fatal_missing_var
#
JAIL_FATAL="${usb_AUDIOBOOKS_destination}"
fatal_missing_var
#
JAIL_FATAL="${usb_EBOOKS_source}"
fatal_missing_var
#
JAIL_FATAL="${usb_EBOOKS_destination}"
fatal_missing_var
#
#
#+----------------------------+
#+---"Main Script Contents"---+
#+----------------------------+
grep -qs "$usb_transfer_mount" /proc/mounts #if grep sees the mount then it will return a silent 0 if not seen a silent 1
if [[ $? -eq 0 ]]; then
  edebug "USB Drive already mounted"
  mountpoint=$(grep "$usb_transfer_mount" /proc/mounts | cut -c 1-9)
  enotify "mountpoint is $mountpoint"
  check_space
  message_form=$(echo "USB DETECTED - Sync starting, please wait...")
  edebug "Message form would be: $message_form"
  pushover
  #start rsync stuff
  section="usb_TV"
  rsync_command
  section="usb_MOVIES"
  rsync_command
  section="usb_MUSIC"
  rsync_command
  section="usb_AUDIOBOOKS"
  rsync_command
  section="usb_EBOOKS"
  rsync_command
  #carry out exit stuff
  exit_segment
elif [[ $? -eq 1 ]]; then
    edebug "USB Drive NOT currently mounted."
    if mount -U "$usb_uuid" -t exfat "$usb_transfer_mount"; then
      mountpoint=$(grep "$usb_transfer_mount" /proc/mounts | cut -c 1-9)
      enotify "mountpoint is $mountpoint"
      edebug "USB Drive mounted successfully"
      check_space
      message_form=$(echo "USB DETECTED - Sync starting, please wait...")
      edebug "Message form would be: $message_form"
      pushover
      #start rsync stuff
      section="usb_TV"
      rsync_command
      section="usb_FILMS"
      rsync_command
      section="usb_MUSIC"
      rsync_command
      section="usb_AUDIOBOOKS"
      rsync_command
      section="usb_EBOOKS"
      rsync_command
      #carry out exit stuff
      exit_segment
    else
      eerror "Something went wrong with the mount of the USB..."
      message_form=$(echo "ERROR - Script started but Something went wrong mounting the USB...contact your administrator!")
      edebug "Message_form would be: $message_form"
      pushover
      exit 66
    fi
fi
#+-------------------+
#+---"Script Exit"---+
#+-------------------+
rm -r /tmp/"$lockname"
if [[ $? -ne 0 ]]; then
    eerror "error removing lockdirectory"
    exit 65
else
    enotify "successfully removed lockdirectory"
fi
esilent "$lockname completed"
exit 0
