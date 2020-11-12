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
#if [[ "$musicserver" -eq 0 ]]
#then
#clean_KodiAudio () {
#curl --data-binary '{ "jsonrpc": "2.0", "method": "AudioLibrary.Clean", "id": "mybash"}' -H 'content-type: application/json;' $kodi_MUSIC_assembly
#}
#
# update AudioLibrary
#update_KodiAudio () {
#curl --data-binary '{ "jsonrpc": "2.0", "method": "AudioLibrary.Scan", "id": "mybash"}' -H 'content-type: application/json;' $kodi_MUSIC_assembly
#}
#else
#  echo "no kodi library functions defined as needed"
#fi
#
#
#+-------------------+
#+---Initial Setup---+
#+-------------------+
#
#
#########SOMETHING TO CHECK IF VARIABLES ARE EMPTY????###########
#
# check for config file existance
if [[ ! -f "$config_file" ]]; then
  echo "config file $config_file does not exist, script exiting"
  exit 1
else
  # source config file
  echo "Config file found, using"
  source $config_file
fi
#
# check if log folder exists
if [[ ! -d "$logfolder" ]]; then
    echo "log folder $logfolder does not exist, attempting to create..."
    #mkdir -p $logfolder
    script_log="$logfolder/MusicSync.log"
    touch $script_log
else
  echo "log directory exists, using this location"
fi
#
# check if beets is intalled
if [[ ! -f "/home/jlivin25/.local/bin/beet" ]]; then
    echo "a beets install at $beets_path not detected, please install and re-run"
    exit 1
else
  source "$beets_path"
fi
#
#
#+---------------------------+
#+---Start Conversion Work---+
#+---------------------------+
#
# ALAC - convert flacs to alac and copy to the ALAC library imports first by using -c flag to specify an alternative config to merge"
if [[ "$music_alac" -eq 1 ]]
then
  echo "ALAC conversion started"
  "$beets_path" "$beets_switch" "$beets_alac_path"/alac_config.yaml import -q "$download_flac"
  rm "$beets_alac_path"/musiclibrary.blb
  "$beets_path" "$beets_switch" "$beets_alac_path"/alac_config.yaml import -q "$rip_flac"
  rm "$beets_alac_path"/musiclibrary.blb
  echo "ALAC conversion finished"
else
  echo "ALAC conversion not selected"
fi
#
#
# UPLOAD - convert the flac files to mp3 and copy to the UPLOAD directory
if [[ "$music_google" -eq 1 ]]
then
  echo ".mp3 UPLOAD started"
  "$beets_path" "$beets_switch" "$beets_upload_path"/uploads_config.yaml import -q "$download_flac"
  rm "$beets_upload_path"/musiclibrary.blb
  "$beets_path" "$beets_switch" "$beets_upload_path"/uploads_config.yaml import -q "$rip_flac"
  rm "$beets_upload_path"/musiclibrary.blb
  echo ".mp3 UPLOAD finished"
else
  echo ".mp3 UPLOAD not selected"
fi
#
#
# FLAC - correct the flac file tags now and move to the FLAC import library using -c flac to specify an alternative config to merge
if [[ "$music_flac" -eq 1 ]]
then
  echo "FLAC conversion started"
  "$beets_path" "$beets_switch" "$beets_flac_path"/flac_config.yaml import -q "$download_flac"
  rm "$beets_flac_path"/musiclibrary.blb
  "$beets_path" "$beets_switch" "$beets_flac_path"/flac_config.yaml import -q "$rip_flac"
  rm "$beets_flac_path"/musiclibrary.blb
  echo "FLAC conversion finished"
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
rsync $rsync_variable2 $rsync_variable7 $rsync_altswitch $flaclibrary_source $FLAC_musicdest
# Sync ALACs
rsync $rsync_variable2 $rsync_variable7 $rsync_altswitch $alaclibrary_source $M4A_musicdest
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
  echo "-------------------------------------------------------------------------------------" >> $logfolder/$logname.log
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MUSIC SERVER sync SELECTED, sync started" >> $logfolder/$logname.log
  rsync "$rsync_altswitch" "$musicserver_source" "$musicserver_user"@"$musicserver_ip":"$musicserver_dest"
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MUSIC SERVER sync finished" >> $logfolder/$logname.log
  update_KodiAudio
  sleep 30s
  clean_KodiAudio
else
  echo "-------------------------------------------------------------------------------------" >> $logfolder/$logname.log
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MUSIC SERVER sync DESELECTED, no sync" >> $logfolder/$logname.log
fi
#
#
# all done
exit
