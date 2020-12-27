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
  should_sync="y"
 else
  log_deb "$download_flac is empty, no conversion needed"
 fi
 if find "$rip_flac" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
  log "files located in $rip_flac"
  "$beets_path" "$beets_switch" "$beets_config_path"/"$config_yaml" import -q "$rip_flac"
  rm "$beets_config_path"/musiclibrary.blb
  should_sync="y"
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
delete_function () {
  find "$location" -mindepth 1 -type f -print
  sleep $sleep_time
  find "$location" -mindepth 1 -type f -delete
  sleep $sleep_time
  find "$location" -mindepth 1 -type d -delete
  sleep $sleep_time
}
#
function Logic1 () {
  if [ "$test_flac_down" = "y" ] || [ "$test_flac_rip" = "y" ] && [ -z "$rsync_error_flag" ]; then
    find "$location2" -mindepth 1 -print -quit 2>/dev/null | grep -q . #<---Command above returns 0 for contents found, or 1 if nothing found
    if [[ "$?" = "0" ]]; then
      log "Test conditions met, I am deleting..."
      location="$download_flac"
      delete_function
      location="$rip_flac"
      delete_function
      location="$location2"
      if [ -z "$location2" ]; then
       log_deb "No second delete location set"
      else
       delete_function
      fi
    else
      log_deb "Test codition not met, found files in $download_flac or $rip_flac but none in $location2, possible failed conversion"
    fi
  else
    log_err "Expected files in $download_flac or $rip_flac and no rsync errors, one of these conditions failes"
    exit 1
  fi
}
#
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
config_yaml="alac_config.yaml"
log "config.yaml set as $config_yaml"
beets_config_path=$(echo $beets_alac_path)
log "beets_config_path set as $beets_config_path"
section=${config_yaml::-12}
log "section running is $section"
if [[ "$music_alac" -eq 1 ]]
then
  beets_function
  sleep 1s
  if [[ "$should_sync" == "y" ]]
  then
    log "$section sync started"
    rsync $rsync_remove_source $rsync_prune_empty $rsync_alt_vzr $alaclibrary_source $M4A_musicdest
    rsync_error_catch
    log "$section sync finished"
  else
    log "no $section conversions, so no sync"
  fi
else
  log "$section conversion not selected" #<---I think this is the issue with the spurious logging name error
fi
#
# UPLOAD - convert the flac files to mp3 and copy to the UPLOAD directory
config_yaml="uploads_config.yaml"
beets_config_path=$(echo $beets_upload_path)
section=${config_yaml::-12}
if [[ "$music_google" -eq 1 ]]
then
  beets_function
else
  log "$section not selected"
fi
#
# FLAC - correct the flac file tags now and move to the FLAC import library using -c flac to specify an alternative config to merge
config_yaml="flac_config.yaml"
log "config.yaml set as $config_yaml"
beets_config_path=$(echo $beets_flac_path)
log "beets_config_path set as $beets_config_path"
section=${config_yaml::-12}
log "section running is $section"
if [[ "$music_flac" -eq 1 ]]
then
  beets_function
  sleep 1s
  if [[ "$should_sync" == "y" ]]
  then
    log "$section sync started"
    rsync $rsync_remove_source $rsync_prune_empty $rsync_alt_vzr $flaclibrary_source $FLAC_musicdest
    rsync_error_catch
    log "$section sync finished"
  else
    log "no $section conversions, so no sync"
  fi
else
  log "$section conversion not selected"
fi
#
#+-------------------------------+
#+---Begin deletion constructs---+
#+-------------------------------+
#
# Check if source folders contain files
function check_source() {
  find "$download_flac" -mindepth 1 -print -quit 2>/dev/null | grep -q . #<---Command above returns 0 for contents found, or 1 if nothing found
  if [[ "$?" = "0" ]]; then
    log "Located files in directory $download_flac"
    test_flac_down="y"
  else
    log "no files located in directory $download_flac"
    test_flac_down="n"
  fi
  find "$rip_flac" -mindepth 1 -print -quit 2>/dev/null | grep -q . #<---Command above returns 0 for contents found, or 1 if nothing found
  if [[ "$?" = "0" ]]; then
    log "Located files in directory $rip_flac"
    test_flac_rip="y"
  else
    log "no files located in directory $rip_flac"
    test_flac_rip="n"
  fi
}
#
# 1: Check if only ALAC conversion is selected
if [ "$music_alac" = "1" ] && [ "$music_flac" = "0" ] && [ "$music_google" = "0" ]; then
  check_source
  location2="$alaclibrary_source"
  sleep_time="2s"
  Logic1
fi
#
# 2: Check if only FLAC conversion is selected
if [ "$music_alac" = "0" ] && [ "$music_flac" = "1" ] && [ "$music_google" = "0" ]; then
  check_source
  location2="$flaclibrary_source"
  sleep_time="2s"
  Logic1
fi
#
# 3: Check if only MP3 Upload is selected
if [ "$music_alac" = "0" ] && [ "$music_flac" = "0" ] && [ "$music_google" = "1" ]; then
  check_source
  location2="$upload_mp3"
  sleep_time="2s"
  Logic1
fi
#
#
# 4: Check if both ALAC & FLAC are selected
if [ "$music_alac" = "1" ] && [ "$music_flac" = "1" ] && [ "$music_google" = "0" ]; then
  check_source
  location2="$alaclibrary_source"
  sleep_time="2s"
  Logic1
  location3="$flaclibrary_source"
  find "$location3" -mindepth 1 -print -quit 2>/dev/null | grep -q . #<---Command above returns 0 for contents found, or 1 if nothing found
  if [[ "$?" = "0" ]]; then
    location="$location3"
    delete_function
  fi
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
