#!/usr/bin/env bash
#
########################################################################################################
## this script is to move downloaded media from a remote source, such as raspberry pi,                ##
## it moves media from the remote to the media source (local machine) using an rsync pull             ##
## script is in user bin folder and run via crontab -e                                                ##
## Ensure config.sh config file & helper files are found or linked in /usr/local/bin and with correct ##                                                      ##
########################################################################################################
#
#+--------------------------+
#+---Source helper script---+
#+--------------------------+
PATH=/sbin:/bin:/usr/bin:/home/jlivin25:/home/jlivin25/.local/bin:/home/jlivin25/bin
helper_file="/usr/local/bin/helper_script.sh"
if [[ ! -f "$helper_file" ]]; then
  echo "helper script $helper_file does not exist, script exiting"
  exit 65
else
  echo "helper script found, using"
  source "$helper_file"
fi
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
#+---------------------+
#+---"Set Variables"---+
#+---------------------+
version="2.0"
scriptlong=`basename "$0"` # imports the name of this script
lockname=${scriptlong::-3} # reduces the name to remove .sh
config_file="/usr/local/bin/config.sh"
script_pid=$(echo $$)
#set default logging level
verbosity=3
#
#
#+--------------------------------------+
#+---"Display some info about script"---+
#+--------------------------------------+
edebug "Version of $scriptlong is: $version"
edebug "PID is $script_pid"
#
#
#+---------------------------------------+
#+---"check if script already running"---+
#+---------------------------------------+
check_running
#
#
#+---------------------------------------+
#+---"Import sensitive data from file"---+
#+---------------------------------------+
#check for config file
if [[ ! -f "$config_file" ]]; then
  enotify "config file $config_file does not exist, script exiting"
  exit 65
  rm -r /tmp/"$lockname"
else
  enotify "config file found, using"
  source "$config_file"
fi
#
#
#+-----------------+
#+---"Functions"---+
#+-----------------+
rsync_error_catch () {
  if [ $? == "0" ]
   then
    enotify "section: $section rsync completed successfully"
   else
    enotify "Section: $section produced an error"
  fi
}
#
helpFunction () {
   echo ""
   echo "Usage: $0 syncmediadownloads.sh"
   echo "Usage: $0 syncmediadownloads.sh -G"
   echo -e "\t Running the script with no flags causes default behaviour with logging level set via 'verbosity' variable"
   echo -e "\t-s Override set verbosity to specify silent log level"
   echo -e "\t-V Override set verbosity to specify Verbose log level"
   echo -e "\t-G Override set verbosity to specify Debug log level"
   echo -e "\t-h Use this flag for help"
   if [ -d "/tmp/$lockname" ]; then
     edebug "removing lock directory"
     rm -r "/tmp/$lockname"
   else
     edebug "problem removing lock directory"
   fi
   exit 1 # Exit script after printing help
}
#
#
#+------------------------+
#+---"Get User Options"---+
#+------------------------+
OPTIND=1
while getopts ":sVGh:" opt
do
    case "${opt}" in
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
#
#
#+-------------------------+
#+---"Start Main Script"---+
#+-------------------------+
esilent "$scriptlong Started, sleeping for 1min to allow network to start"
edebug "username is set as $username; USER is set at $USER and config file is $config_file"  #for error checking
edebug "syncmediadownloads PID is: $script_pid"
sleep 15s #sleep for cron @reboot to allow time for network to start
#
#
#+-----------------------+
#+---"AUDIOBOOKS Sync"---+
#+-----------------------+
section="audiobooks"
if [[ "$section" -eq 1 ]]
then
  enotify "AUDIOBOOKS sync SELECTED, sync started"
  rsync $rsync_prune_empty $rsync_set_perms $rsync_set_OwnGrp $rsync_set_chmod $rsync_set_chown $rsync_protect_args $rsync_vzrc "$downloadbox_user"@"$downloadbox_ip":"$audiobook_source" "$audiobook_dest"
  rsync_error_catch
  update_audiolibrary # update Audio Library on Kodi Video Server
  enotify "AUDIOBOOKS sync finished"
else
  enotify "AUDIOBOOKS sync DESELECTED, no sync"
fi
#
#
#+-------------------+
#+---"EBOOKS Sync"---+
#+-------------------+
section="ebooks"
if [[ "$section" -eq 1 ]]
then
  enotify "EBOOKS sync SELECTED, sync started"
  rsync $rsync_prune_empty $rsync_set_perms $rsync_set_OwnGrp $rsync_set_chmod $rsync_set_chown $rsync_protect_args $rsync_vzrc "$downloadbox_user"@"$downloadbox_ip":"$ebook_source" "$ebook_dest"
  rsync_error_catch
  update_audiolibrary # update Audio Library on Kodi Video Server
  enotify "EBOOKS sync finished"
else
  enotify "EBOOKS sync DESELECTED, no sync"
fi
#
#
#+------------------+
#+---"MUSIC Sync"---+
#+------------------+
section="music_sync"
if [[ "$section" -eq 1 ]]
then
  enotify "MUSIC sync SELECTED, sync started"
  rsync $rsync_prune_empty $rsync_set_perms $rsync_set_OwnGrp $rsync_set_chmod $rsync_set_chown $rsync_protect_args $rsync_remove_source $rsync_vzrc "$downloadbox_user"@"$downloadbox_ip":"$lossless_source" "$lossless_dest"
  rsync_error_catch
  enotify "Starting MusicSync.sh"
  sudo -u jlivin25 $HOME/bin/sync_scripts/MusicSync.sh #run seperate 'tagger' script
  script_exit
else
  enotify "MUSIC sync DESELECTED, no sync"
fi
#
#
#+-----------------+
#+---"FILM Sync"---+
#+-----------------+
section="movies"
if [[ "section" -eq 1 ]]
then
  enotify "MOVIES sync SELECTED, sync started"
  rsync $rsync_prune_empty $rsync_set_perms $rsync_set_OwnGrp $rsync_set_chmod $rsync_set_chown $rsync_protect_args $rsync_remove_source $rsync_vzrc "$downloadbox_user"@"$downloadbox_ip":"$movie_source" "$movie_dest"
  rsync_error_catch
  update_videolibrary # update Video Library on Kodi Video Server
  enotify "MOVIES sync COMPLETE"
else
  enotify "MOVIES sync DESELECTED, no sync"
fi
#
#
#+---------------+
#+---"TV Sync"---+
#+---------------+
section="tv"
if [[ "$section" -eq 1 ]]
then
  enotify "TV sync SELECTED, sync started"
  rsync $rsync_prune_empty $rsync_set_perms $rsync_set_OwnGrp $rsync_set_chmod $rsync_set_chown $rsync_protect_args $rsync_remove_source $rsync_vzrc "$downloadbox_user"@"$downloadbox_ip":"$tv_source" "$tv_dest"
  rsync_error_catch
  update_videolibrary # update Video Library on Kodi Video Server
  enotify "TV sync finished"
else
  enotify "TV sync DESELECTED, no sync"
fi
#
#
#+----------------+
#+---"NFL Sync"---+
#+----------------+
section="nfl"
if [[ "$section" -eq 1 ]]
then
  enotify "NFL sync SELECTED, sync started"
  rsync $rsync_prune_empty $rsync_vzrc "$downloadbox_user"@"$downloadbox_ip":"$nfl_source" "$nfl_dest"
  rsync_error_catch
  enotify "NFL sync finished"
else
  enotify "NFL sync DESELECTED, no sync"
fi
#
esilent "$scriptlong complete"
#
#
rm -r /tmp/"$lockname"
exit 0
