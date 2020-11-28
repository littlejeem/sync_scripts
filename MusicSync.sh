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
  echo "JAIL_FATAL is unset or set to the empty string, script cannot continue. Exiting!"
  exit 1
 else
  echo "variable found, using: $JAIL_FATAL"
 fi
}
#
debug_missing_var () {
 if [ -z "${JAIL_DEBUG}" ]; then
  echo "JAIL_DEBUG is unset or set to the empty string, may cause issues"
 else
  echo "variable found, using: $JAIL_DEBUG"
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
#INDIVIDUAL BEETS FUNCTIONS IF SINGLE DOESNT WORK
beets_function_alac () {
 config_yaml="alac_config.yaml"
 echo "ALAC conversion started"
 "$beets_path" "$beets_switch" "$beets_alac_path"/"$config_yaml" import -q "$download_flac"
 rm "$beets_alac_path"/musiclibrary.blb
 "$beets_path" "$beets_switch" "$beets_alac_path"/"$config_yaml" import -q "$rip_flac"
 rm "$beets_alac_path"/musiclibrary.blb
 echo "ALAC conversion finished"
}
#
beets_function_upload () {
 config_yaml="uploads_config.yaml"
 echo ".mp3 UPLOAD started"
 "$beets_path" "$beets_switch" "$beets_upload_path"/"$config_yaml" import -q "$download_flac"
 rm "$beets_upload_path"/musiclibrary.blb
 "$beets_path" "$beets_switch" "$beets_upload_path"/"$config_yaml" import -q "$rip_flac"
 rm "$beets_upload_path"/musiclibrary.blb
 echo ".mp3 UPLOAD finished"
}
#
beets_function_flac () {
 config_yaml="flac_config.yaml"
 echo "FLAC conversion started"
 "$beets_path" "$beets_switch" "$beets_flac_path"/"$config_yaml" import -q "$download_flac"
 rm "$beets_flac_path"/musiclibrary.blb
 "$beets_path" "$beets_switch" "$beets_flac_path"/"$config_yaml" import -q "$rip_flac"
 rm "$beets_flac_path"/musiclibrary.blb
 echo "FLAC conversion finished"
}
#
#
#+-------------------+
#+---Initial Setup---+
#+-------------------+
#
#SET TEMPORARY VARIABLE FOR TESTING
config_file="$HOME/.config/ScriptSettings/sync_config.sh"
#
#
# check for config file existance
if [[ ! -f "$config_file" ]]; then
  echo "config file $config_file does not exist, script exiting"
  exit 1
else
  # source config file
  echo "Config file found, using $config_file"
  source $config_file
fi
#
# check if log folder exists
if [[ ! -d "$logfolder" ]]; then
    echo "log folder $logfolder does not exist, attempting to create..."
    #mkdir -p $logfolder
    script_log="$logfolder/MusicSync.log"
    if [[ ! -f "$script_log" ]]; then
      echo "log file found, using: $script_log"
    else
    touch $script_log
else
  echo "log directory exists, using this location"
  touch $script_log
fi
#
# check if beets is intalled
if [[ ! -f "$beets_path" ]]; then
    echo "a beets install at $beets_path not detected, please install and re-run"
    exit 1
else
  echo "Beets install detected, using $beets_path"
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
  echo "ALAC conversion started"
  beets_function
  echo "ALAC conversion finished"
  sleep 1
  echo "ALAC sync started"
  rsync $rsync_remove_source $rsync_prune_empty $rsync_alt_vzr $alaclibrary_source $M4A_musicdest
  echo "ALAC sync finished"
else
  echo "ALAC conversion not selected"
fi
#
#
# UPLOAD - convert the flac files to mp3 and copy to the UPLOAD directory
if [[ "$music_google" -eq 1 ]]
then
  config_yaml="uploads_config.yaml"
  beets_config_path=$(echo $beets_upload_path)
  echo ".mp3 UPLOAD started"
  beets_function
  echo ".mp3 UPLOAD finished"
else
  echo ".mp3 UPLOAD not selected"
fi
#
#
# FLAC - correct the flac file tags now and move to the FLAC import library using -c flac to specify an alternative config to merge
if [[ "$music_flac" -eq 1 ]]
then
  config_yaml="flac_config.yaml"
  beets_config_path=$(echo $beets_flac_path)
  echo "FLAC conversion started"
  beets_function
  echo "FLAC conversion finished"
  sleep 1
  echo "FLAC sync started"
  rsync $rsync_remove_source $rsync_prune_empty $rsync_alt_vzr $flaclibrary_source $FLAC_musicdest
  echo "FLAC sync finished"
else
  echo "FLAC conversion not selected"
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
  echo "-------------------------------------------------------------------------------------" >> $script_log
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MUSIC SERVER sync SELECTED, sync started" >> $script_log
  rsync "$rsync_alt_vzr" "$musicserver_source" "$musicserver_user"@"$musicserver_ip":"$musicserver_dest"
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MUSIC SERVER sync finished" >> $script_log
  update_KodiAudio
  sleep 30s
  clean_KodiAudio
else
  echo "-------------------------------------------------------------------------------------" >> $script_log
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MUSIC SERVER sync DESELECTED, no sync" >> $script_log
fi
#
#
# all done
exit
