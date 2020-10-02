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
####################################
## Import settings data from file ##
####################################
#
version=2.0
config_file="$HOME/.config/ScriptSettings/sync_config.sh"
#
######################
## Define Functions ##
######################
#
# clean Audiolibrary
if [[ "$musicserver" -eq 0 ]]
then
clean_KodiAudio () {
curl --data-binary '{ "jsonrpc": "2.0", "method": "AudioLibrary.Clean", "id": "mybash"}' -H 'content-type: application/json;' $kodi_MUSIC_assembly
}
#
# update AudioLibrary
update_KodiAudio () {
curl --data-binary '{ "jsonrpc": "2.0", "method": "AudioLibrary.Scan", "id": "mybash"}' -H 'content-type: application/json;' $kodi_MUSIC_assembly
}
else
  echo "no kodi library functions defined as needed"
fi
#
# deleting if
delete_if () {
  DIR=${PWD}
  if [ ! "$(ls -A "$DIR")" ]
  then
      echo ""$DIR" is empty, no action"
  else
      echo ""$DIR" is not empty, deleting files"
      rm -r *
  fi
}
#
# Logging functions
SCRIPTENTRY () {
 timeAndDate=`date`
 script_name=`basename "$0"`
 script_name="${script_name%.*}"
 echo "[$timeAndDate] [DEBUG]  > $script_name $FUNCNAME" >> $script_log
}
#
SCRIPTEXIT () {
 script_name=`basename "$0"`
 script_name="${script_name%.*}"
 echo "[$timeAndDate] [DEBUG]  < $script_name $FUNCNAME" >> $script_log
}
#
ENTRY () {
 local cfn="${FUNCNAME[1]}"
 timeAndDate=`date`
 echo "[$timeAndDate] [DEBUG]  > $cfn $FUNCNAME" >> $script_log
}
#
EXIT () {
 local cfn="${FUNCNAME[1]}"
 timeAndDate=`date`
 echo "[$timeAndDate] [DEBUG]  < $cfn $FUNCNAME" >> $script_log
}
#
INFO () {
 local function_name="${FUNCNAME[1]}"
    local msg="$1"
    timeAndDate=`date`
    echo "[$timeAndDate] [INFO]  $msg" >> $script_log
}
#
DEBUG () {
 local function_name="${FUNCNAME[1]}"
    local msg="$1"
    timeAndDate=`date`
 echo "[$timeAndDate] [DEBUG]  $msg" >> $script_log
}
#
ERROR () {
 local function_name="${FUNCNAME[1]}"
    local msg="$1"
    timeAndDate=`date`
    echo "[$timeAndDate] [ERROR]  $msg" >> $script_log
}
#
##################
# Initial Setup ##
##################
#check for config file
if [[ ! -f "$config_file" ]]; then
    echo "config file $config_file does not exist, script exiting"
    exit 1
fi
#source config file
source "$HOME/.config/ScriptSettings/sync_config.sh"
#check if log folder exists
if [[ ! -d "$logfolder" ]]; then
    echo "log folder $logfolder does not exist, attempting to create..."
    #mkdir -p $logfolder
    script_log="$logfolder/MusicSync.log"
    touch $script_log
fi
#
#
#######################
## Start Main Script ##
#######################
#
# start MUSIC Import
# ALAC - convert flacs to alac and copy to the ALAC library imports first by using -c flag to specify an alternative config to merge
"$beets_path" "$beets_switch" "$beets_alac_path"/alac_config.yaml import -q "$download_flac"
rm "$beets_alac_path"/musiclibrary.blb
"$beets_path" "$beets_switch" "$beets_alac_path"/alac_config.yaml import -q "$rip_flac"
rm "$beets_alac_path"/musiclibrary.blb
# UPLOAD - convert the flac files to mp3 and copy to the UPLOAD directory
"$beets_path" "$beets_switch" "$beets_upload_path"/uploads_config.yaml import -q "$download_flac"
rm "$beets_upload_path"/musiclibrary.blb
"$beets_path" "$beets_switch" "$beets_upload_path"/uploads_config.yaml import -q "$rip_flac"
rm "$beets_upload_path"/musiclibrary.blb
# FLAC - correct the flac file tags now and move to the FLAC import library using -c flac to specify an alternative config to merge
"$beets_path" "$beets_switch" "$beets_flac_path"/flac_config.yaml import -q "$download_flac"
rm "$beets_flac_path"/musiclibrary.blb
"$beets_path" "$beets_switch" "$beets_flac_path"/flac_config.yaml import -q "$rip_flac"
rm "$beets_flac_path"/musiclibrary.blb
#
#
# sync tagged flac files next
cd "$flaclibrary_source"
DIR=${PWD}
if [ ! "$(ls -A "$DIR")" ]
then
    echo ""$DIR" is empty, no action" >> "$logfolder"/"$logname".log
else
    echo ""$DIR" is not empty, copying then deleting files"
    sleep 5s
    cp -rpv "$flaclibrary_source"/* "$FLAC_musicdest"
    rm -r *
fi
#
#
# sync alac music files next
cd "$alaclibrary_source"
DIR=${PWD}
if [ ! "$(ls -A "$DIR")" ]
then
    echo ""$DIR" is empty, no action"
else
    echo ""$DIR" is not empty, copying then deleting files"
    sleep 5s
    cp -rpv "$alaclibrary_source"/* "$M4A_musicdest"
    rm -r *
fi
#
#
# tidy up source download directory
cd "$download_flac"
delete_if
#
# tidy up source rip directory
cd "$rip_flac"
delete_if
#
# tidy up upload directory
cd "$upload_mp3"
delete_if
#
#
#########################
### MUSIC SERVER sync ###
#########################
if [[ "$musicserver" -eq 1 ]]
then
  echo "-------------------------------------------------------------------------------------" >> $logfolder/$logname.log
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MUSIC SERVER sync SELECTED, sync started" >> $logfolder/$logname.log
  rsync "$rsync_altswitch" "$musicserver_source" "$musicserver_user"@"$musicserver_ip":"$musicserver_dest"
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MUSIC SERVER sync finished" >> $logfolder/$logname.log
else
  echo "-------------------------------------------------------------------------------------" >> $logfolder/$logname.log
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MUSIC SERVER sync DESELECTED, no sync" >> $logfolder/$logname.log
fi
update_KodiAudio
sleep 30s
clean_KodiAudio
#
#
# all done
exit
