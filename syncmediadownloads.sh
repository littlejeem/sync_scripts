#!/usr/bin/env bash
#
#############################################################################################
## this script is to move downloaded media from a remote source, such as raspberry pi,     ##
## it moves media from the remote to the media source (local machine) using an rsync pull  ##
## script is in user bin folder but run from sudo or su cron not user                      ##
#############################################################################################
#
#+--------------------------+
#+---Source helper script---+
#+--------------------------+
PATH=/sbin:/bin:/usr/bin:/home/jlivin25:/home/jlivin25/.local/bin:/home/jlivin25/bin
helper_file="$HOME/bin/standalone_scripts/helper_script.sh"
if [[ ! -f "$helper_file" ]]; then
  echo "config file $config_file does not exist, script exiting"
  exit 65
else
  echo "config file found, using"
  source "$HOME/bin/standalone_scripts/helper_script.sh"
fi
#
#
#+------------------+
#+---"Exit Codes"---+
#+------------------+
# pick from 64 - 113 (https://tldp.org/LDP/abs/html/exitcodes.html#FTN.AEN23647)
# exit 0 = Success
# exit 64 = Variable Error
# exit 65 = Sourcing file/folder error
# exit 66 = Processing Error
# exit 67 = Required Program Missing
#
#
#+---------------------+
#+---"Set Variables"---+
#+---------------------+
version="2.0"
scriptlong=`basename "$0"` # imports the name of this script
lockname=${scriptlong::-3} # reduces the name to remove .sh
config_file="$HOME/.config/ScriptSettings/sync_config.sh"
script_pid=$(echo $$)
#
#
#+--------------------------------------+
#+---"Display some info about script"---+
#+--------------------------------------+
log_deb "Version of $scriptlong is: $version"
log_deb "PID is $script_pid"
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
  log "config file $config_file does not exist, script exiting"
  exit 65
  rm -r "$lockname"
else
  log "config file found, using"
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
    log "section: $section rsync completed successfully"
   else
    log "Section: $section produced an error"
  fi
}
#
#
#+-------------------------+
#+---"Start Main Script"---+
#+-------------------------+
log "$scriptlong Started, sleeping for 1min to allow network to start"
log_deb "username is set as $username; USER is set at $USER and config file is $config_file"  #for error checking
log_deb "syncmediadownloads PID is: $script_pid"
sleep 15s #sleep for cron @reboot to allow time for network to start
#
#
#+------------------+
#+---"MUSIC Sync"---+
#+------------------+
section="music_sync"
if [[ "$section" -eq 1 ]]
then
  log "MUSIC sync SELECTED, sync started"
  rsync "$rsync_prune_empty" "$rsync_set_perms" "$rsync_set_OwnGrp" "$rsync_set_chmod" "$rsync_set_chown" "$rsync_protect_args" "$rsync_remove_source" "$rsync_vzrc" "$downloadbox_user"@"$downloadbox_ip":"$lossless_source" "$lossless_dest"
  rsync_error_catch
  log "Starting MusicSync.sh"
  sudo -u jlivin25 $HOME/bin/sync_scripts/MusicSync.sh #run seperate 'tagger' script
  script_exit
else
  log "MUSIC sync DESELECTED, no sync"
fi
#
#
#+-----------------+
#+---"FILM Sync"---+
#+-----------------+
section="movies"
if [[ "section" -eq 1 ]]
then
  log "MOVIES sync SELECTED, sync started"
  rsync "$rsync_prune_empty" "$rsync_set_perms" "$rsync_set_OwnGrp" "$rsync_set_chmod" "$rsync_set_chown" "$rsync_protect_args" "$rsync_remove_source" "$rsync_vzrc" "$downloadbox_user"@"$downloadbox_ip":"$movie_source" "$movie_dest"
  rsync_error_catch
  update_videolibrary # update Video Library on Kodi Video Server
  log "MOVIES sync COMPLETE"
else
  log "MOVIES sync DESELECTED, no sync"
fi
#
#
#+---------------+
#+---"TV Sync"---+
#+---------------+
section="tv"
if [[ "$section" -eq 1 ]]
then
  log "TV sync SELECTED, sync started"
  rsync "$rsync_prune_empty" "$rsync_set_perms" "$rsync_set_OwnGrp" "$rsync_set_chmod" "$rsync_set_chown" "$rsync_protect_args" "$rsync_remove_source" "$rsync_vzrc" "$downloadbox_user"@"$downloadbox_ip":"$tv_source" "$tv_dest"
  rsync_error_catch
  update_videolibrary # update Video Library on Kodi Video Server
  log "TV sync finished"
else
  log "TV sync DESELECTED, no sync"
fi
#
#
#+----------------+
#+---"NFL Sync"---+
#+----------------+
section="nfl"
if [[ "$section" -eq 1 ]]
then
  log "NFL sync SELECTED, sync started"
  rsync "$rsync_prune_empty" "$rsync_vzrc" "$downloadbox_user"@"$downloadbox_ip":"$nfl_source" "$nfl_dest"
  rsync_error_catch
  log "NFL sync finished"
else
  log "NFL sync DESELECTED, no sync"
fi
#
log "$scriptlong complete"
#
#
rm -r "$lockname"
exit 0
