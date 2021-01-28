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
source $HOME/bin/standalone_scripts/helper_script.sh
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
####################
## set variables  ##
####################
version="v2.0"
scriptlong=`basename "$0"` # imports the name of this script
lockname=${scriptlong::-3} # reduces the name to remove .sh
logname=$lockname.log # Uses the script name to create the log
stamp=$(echo "SYNC-`date +%d_%m_%Y`-`date +%H.%M.%S`")
stamplog=$(echo "`date +%d%m%Y`-`date +%H_%M_%S`")
dir_name="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
config_file="$HOME/.config/ScriptSettings/sync_config.sh"
script_pid=$(echo $$)
#
#
#+---------------------------------------+
#+---"check if script already running"---+
#+---------------------------------------+
#temp_dir="/tmp/syncmediadownloads"
#if [[ -d "$temp_dir" ]]; then
#  while [[ -d "$temp_dir" ]]; do
#    log "previous script still running"
#    sleep 2m; done
#  else
#    log "no previously running script detected"
#fi
#log_deb "temp dir is set as: $temp_dir"
#mkdir "$temp_dir"
#if [[ $? = 0 ]]; then
#  log "temp directory set successfully"
#else
#  log_err "temp directory NOT set successfully, exiting"
#  exit 2
#fi
#
#
#####################################
## Import sensitive data from file ##
#####################################
#check for config file
if [[ ! -f "$config_file" ]]; then
  log "config file $config_file does not exist, script exiting"
  exit 2
  rm -r "$temp_dir"
else
  log "config file found, using"
  source "$config_file"
fi
#
#
##############################################################
## set FUNCTIONS - tested on KODI 17/18 for library actions ##
##############################################################
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
#######################
## Start Main Script ##
#######################
mkdir -p "$logfolder"
log "$scriptlong Started, sleeping for 1min to allow network to start"
log_deb "username is set as $username; USER is set at $USER and config file is $config_file"  #for error checking
log_deb "syncmediadownloads PID is: $script_pid"
sleep 15s #sleep for cron @reboot to allow tine for network to start
#
#
################
## MUSIC sync ##
################
section="music_sync"
if [[ "$section" -eq 1 ]]
then
  log "MUSIC sync SELECTED, sync started"
  rsync "$rsync_prune_empty" "$rsync_set_perms" "$rsync_set_OwnGrp" "$rsync_set_chmod" "$rsync_set_chown" "$rsync_protect_args" "$rsync_remove_source" "$rsync_vzrc" "$downloadbox_user"@"$downloadbox_ip":"$lossless_source" "$lossless_dest"
  rsync_error_catch
  log "Starting MusicSync.sh"
  sudo -u jlivin25 $HOME/bin/sync_scripts/MusicSync.sh #run seperate 'tagger' script
  script_exit
#  reply=$?
#  if [[ "$reply" = 0 ]]; then
#    log "MusicSync.sh exited gracefully"
#  else
#    log_err "Exit code: $reply received"
#    log_deb "MusicSync.sh exited with error"
#  fi
#  log "MUSIC sync finished"
else
  log "MUSIC sync DESELECTED, no sync"
fi
#
#
###############
## FILM sync ##
###############
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
#############
## TV sync ##
#############
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
####################
## start NFL sync ##
####################
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
#rm -r "$temp_dir"
exit 0
