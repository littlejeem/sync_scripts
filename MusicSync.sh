#!/usr/bin/env bash
#
#
#################################################################################################
## This script is to import music transferred from the a remote location into Beets Librtary   ##
## Once imported and converted it moves the fies to my music library, this is also done with   ##
## any ripped music                                                                            ##
## script is in $HOME/scripts/control_scripts folder                                                               ##
#################################################################################################
#
#
# Source helper script
PATH=/sbin:/bin:/usr/bin:/home/jlivin25:/home/jlivin25/.local/bin:/home/jlivin25/bin
source $HOME/bin/standalone_scripts/helper_script.sh
#+------------------------+
#+--- Define Functions ---+
#+------------------------+
#
# clean Audiolibrary
clean_KodiAudio () {
 curl --data-binary '{ "jsonrpc": "2.0", "method": "AudioLibrary.Clean", "id": "mybash"}' -H 'content-type: application/json;' $kodi_MUSIC_assembly
}
#
# update AudioLibrary
update_KodiAudio () {
 curl --data-binary '{ "jsonrpc": "2.0", "method": "AudioLibrary.Scan", "id": "mybash"}' -H 'content-type: application/json;' $kodi_MUSIC_assembly
}
#
#
fatal_missing_var () {
 if [ -z "${JAIL_FATAL}" ]; then
  log_err "JAIL_FATAL is unset or set to the empty string, script cannot continue. Exiting!"
  exit 1
 else
  log "variable found, using: $JAIL_FATAL"
 fi
}
#
debug_missing_var () {
 if [ -z "${JAIL_DEBUG}" ]; then
  log_err "JAIL_DEBUG is unset or set to the empty string, may cause issues"
 else
  log "variable found, using: $JAIL_DEBUG"
 fi
}
#
#SINGLE BEETS FUNCTION
beets_function () {
 "$beets_path" "$beets_switch" "$beets_config_path"/"$config_yaml" import -q "$download_flac"
 rm "$beets_config_path"/musiclibrary.blb
 "$beets_path" "$beets_switch" "$beets_config_path"/"$config_yaml" import -q "$rip_flac"
 rm "$beets_config_path"/musiclibrary.blb
}
#
rsync_error_catch () {
  if [ $? == "0" ]
   then
    log "`date +%d/%m/%Y` - `date +%H:%M:%S` rsync completed successfully"
   else
    log_err "`date +%d/%m/%Y` - `date +%H:%M:%S` rsync produced an error"
  fi
}
#
#+-------------------+
#+---Initial Setup---+
#+-------------------+
#
#SET TEMPORARY VARIABLE FOR TESTING
config_file="$HOME/.config/ScriptSettings/sync_config.sh"
#
#
#Check for existance FFMPEG
if ! command -v ffmpeg &> /dev/null
then
  log_err "FFMPEG could not be found, script won't function wihout it"
  exit 1
else
  log "FFMPEG command located, continuing"
fi
#
# check for config file existance
if [[ ! -f "$config_file" ]]; then
  log_err "config file $config_file does not exist, script exiting"
  exit 1
else
  # source config file
  log "Config file found, using $config_file"
  source $config_file
fi
#
# check if log folder exists
if [[ ! -d "$logfolder" ]]; then
  log "log folder $logfolder does not exist, attempting to create..."
  mkdir -p $logfolder
  script_log="$logfolder/MusicSync.log"
  touch $script_log
else
  log "log directory exists, using this location: $logfolder"
  script_log="$logfolder/MusicSync.log"
  if [[ ! -f "$script_log" ]]; then
    log "log file found, using: $script_log"
  else
    log "no log found, creating: $script_log"
    touch $script_log
  fi
fi
#
# check if beets is intalled
if [[ ! -f "$beets_path" ]]; then
    log_err "a beets install at $beets_path not detected, please install and re-run"
    exit 1
else
  log "Beets install detected, using $beets_path"
fi
#
#
#check that necessary variables are set
JAIL_FATAL="${music_alac}"
fatal_missing_var
#
JAIL_FATAL="${download_flac}"
fatal_missing_var
#
JAIL_FATAL="${rip_flac}"
fatal_missing_var
#
JAIL_FATAL="${alaclibrary_source}"
fatal_missing_var
#
JAIL_FATAL="${flaclibrary_source}"
fatal_missing_var
#
JAIL_FATAL="${upload_mp3}"
debug_missing_var
#
JAIL_FATAL="${FLAC_musicdest}"
fatal_missing_var
#
JAIL_FATAL="${M4A_musicdest}"
fatal_missing_var
#
JAIL_FATAL="${beets_switch}"
fatal_missing_var
#
JAIL_FATAL="${beets_flac_path}"
fatal_missing_var
#
JAIL_FATAL="${beets_alac_path}"
fatal_missing_var
#
JAIL_FATAL="${beets_upload_path}"
debug_missing_var
#
#
#+---------------------------+
#+---Start Conversion Work---+
#+---------------------------+
#
# ALAC - convert flacs to alac and copy to the ALAC library imports first by using -c flag to specify an alternative config to merge"
if [[ "$music_alac" -eq 1 ]]
then
  config_yaml="alac_config.yaml"
  beets_config_path=$(echo $beets_alac_path)
  log "ALAC conversion started"
  beets_function
  log "ALAC conversion finished"
  sleep 1
  log "ALAC sync started"
  rsync $rsync_remove_source $rsync_prune_empty $rsync_alt_vzr $alaclibrary_source $M4A_musicdest
  rsync_error_catch
  log "ALAC sync finished"
else
  log "ALAC conversion not selected"
fi
#
#
# UPLOAD - convert the flac files to mp3 and copy to the UPLOAD directory
if [[ "$music_google" -eq 1 ]]
then
  config_yaml="uploads_config.yaml"
  beets_config_path=$(echo $beets_upload_path)
  log ".mp3 UPLOAD started"
  beets_function
  log ".mp3 UPLOAD finished"
else
  log ".mp3 UPLOAD not selected"
fi
#
#
# FLAC - correct the flac file tags now and move to the FLAC import library using -c flac to specify an alternative config to merge
if [[ "$music_flac" -eq 1 ]]
then
  config_yaml="flac_config.yaml"
  beets_config_path=$(echo $beets_flac_path)
  log "FLAC conversion started"
  beets_function
  log "FLAC conversion finished"
  sleep 1
  log "FLAC sync started"
  rsync $rsync_remove_source $rsync_prune_empty $rsync_alt_vzr $flaclibrary_source $FLAC_musicdest
  rsync_error_catch
  log "FLAC sync finished"
else
  log "FLAC conversion not selected"
fi
#
#
#+--------------------------+
#+---Sync converted media---+
#+--------------------------+
# rsync prune -vrc source dest
#
# Sync FLACs

# Sync ALACs

#
#
##########DO WE NEED TO CHECK SUCCESS OF THE RSYNC BEFORE DELETION OF DIRECTORIES###########
#
# tidy up source download directory
#cd "$download_flac"
#delete_if
#
# tidy up source rip directory
#cd "$rip_flac"
#delete_if
#
# tidy up upload directory
#cd "$upload_mp3"
#delete_if
#
#
#########################
### MUSIC SERVER sync ###
#########################
if [[ "$musicserver_sync" -eq 1 ]]
then
  echo "-------------------------------------------------------------------------------------"
  log "MUSIC SERVER sync SELECTED, sync started"
  rsync "$rsync_alt_vzr" "$musicserver_source" "$musicserver_user"@"$musicserver_ip":"$musicserver_dest"
  rsync_error_catch
  log "MUSIC SERVER sync finished"
  update_KodiAudio
  sleep 30s
  clean_KodiAudio
else
  echo "-------------------------------------------------------------------------------------"
  log "MUSIC SERVER sync DESELECTED, no sync"
fi
#
#
# all done
exit
