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
#+--------------------------+
#+---Source helper script---+
#+--------------------------+
PATH=/sbin:/bin:/usr/bin:/home/jlivin25:/home/jlivin25/.local/bin:/home/jlivin25/bin
source $HOME/bin/standalone_scripts/helper_script.sh
#
#
#+------------------------+
#+--- Define Functions ---+
#+------------------------+
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
  log_deb "JAIL_DEBUG is unset or set to the empty string, may cause issues"
 else
  log "variable found, using: $JAIL_DEBUG"
 fi
}
#
#SINGLE BEETS FUNCTION
beets_function () {
 log "$section processing started"
 if find "$download_flac" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
  log "files located in $download_flac"
  "$beets_path" "$beets_switch" "$beets_config_path"/"$config_yaml" import -q "$download_flac"
  rm "$beets_config_path"/musiclibrary.blb
 else
  log_deb "$download_flac is empty, no conversion needed"
 fi
 if find "$rip_flac" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
  log "files located in $rip_flac"
  "$beets_path" "$beets_switch" "$beets_config_path"/"$config_yaml" import -q "$rip_flac"
  rm "$beets_config_path"/musiclibrary.blb
 else
  log_deb "$rip_flac is empty, no conversion needed"
 fi
 log "$section processing finished"
}
#
rsync_error_catch () {
  if [ $? == "0" ]
   then
    log "rsync completed successfully"
   else
    log_err "rsync produced an error"
    rsync_error_flag="y"
  fi
}
#
#+-------------------+
#+---Initial Setup---+
#+-------------------+
#SET TEMPORARY VARIABLE FOR TESTING
config_file="$HOME/.config/ScriptSettings/sync_config.sh"
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
# check if beets is intalled
if [[ ! -f "$beets_path" ]]; then
  log_err "a beets install at $beets_path not detected, please install and re-run"
  exit 1
else
  log "Beets install detected, using $beets_path"
fi
#
#
#+--------------------------------------------+
#+---Check that necessary variables are set---+
#+--------------------------------------------+
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
# ALAC - convert flacs to alac and copy to the ALAC library imports first by using -c flag to specify an alternative config to merge"
if [[ "$music_alac" -eq 1 ]]
then
  config_yaml="alac_config.yaml"
  beets_config_path=$(echo $beets_alac_path)
  section=${config_yaml::-12}
  beets_function
  sleep 1
  log "$section sync started"
  rsync $rsync_remove_source $rsync_prune_empty $rsync_alt_vzr $alaclibrary_source $M4A_musicdest
  rsync_error_catch
  log "$section sync finished"
else
  log "$section conversion not selected" #<---I think this is the issue with the spurious logging name error
fi
#
# UPLOAD - convert the flac files to mp3 and copy to the UPLOAD directory
if [[ "$music_google" -eq 1 ]]
then
  config_yaml="uploads_config.yaml"
  beets_config_path=$(echo $beets_upload_path)
  section=${config_yaml::-12}
  beets_function
else
  log "$section not selected"
fi
#
# FLAC - correct the flac file tags now and move to the FLAC import library using -c flac to specify an alternative config to merge
if [[ "$music_flac" -eq 1 ]]
then
  config_yaml="flac_config.yaml"
  beets_config_path=$(echo $beets_flac_path)
  section=${config_yaml::-12}
  beets_function
  sleep 1
  log "$section sync started"
  rsync $rsync_remove_source $rsync_prune_empty $rsync_alt_vzr $flaclibrary_source $FLAC_musicdest
  rsync_error_catch
  log "$section sync finished"
else
  log "$section conversion not selected"
fi
#
#+-------------------------------+
#+---Begin deletion constructs---+
#+-------------------------------+
# 1: Check if source folders contain files
find "$download_flac" -mindepth 1 -print -quit 2>/dev/null | grep -q . #<---Command above returns 0 for contents found, or 1 if nothing found
if [[ "$?" = "0" ]]; then
  log "Located files in directory $download_flac"
  test1="y"
else
  log "no files located in directory $download_flac"
  test1="n"
fi
#
find "$flaclibrary_source" -mindepth 1 -print -quit 2>/dev/null | grep -q . #<---Command above returns 0 for contents found, or 1 if nothing found
if [[ "$?" = "0" ]]; then
  log "Located files in directory $flaclibrary_source"
  test2="y"
else
  log "no files located in directory $flaclibrary_source"
  test2="n"
fi
#
# 2: Set test conditions necessary for deletion, logic here if there are no rsync errors and files in flac source and flac library, deletion can be carried out
if [ "$test1" == "y" ] && [ "$test2" == 'y' ] && [ -z "$rsync_error_flag" ]; then
  log "Test conditions met, I would delete..."
  find "$download_flac" -mindepth 1 -type f -delete
  find "$rip_flac" -mindepth 1 -type f -delete
  if [[ "$music_alac" -eq 1 ]]; then
    find "$alaclibrary_source" -mindepth 1 -type f -delete
  fi
  if [[ "$music_google" -eq 1 ]]; then
    find "$upload_mp3" -mindepth 1 -type f -delete
  fi
  if [[ "$music_flac" -eq 1 ]]; then
    find "$flaclibrary_source" -mindepth 1 -type f -delete
  fi
else
  echo "Test conditions not met, I wouldnt delete"
fi
#
#
#+-----------------------+
#+---MUSIC SERVER sync---+
#+-----------------------+
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
exit 0
