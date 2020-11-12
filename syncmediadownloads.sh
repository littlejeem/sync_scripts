#!/usr/bin/env bash
#
#############################################################################################
## this script is to move downloaded media from a remote source, such as raspberry pi,     ##
## it moves media from the remote to the media source (local machine) using an rsync pull  ##
## script is in user bin folder but run from sudo or su cron not user                      ##
#############################################################################################
#
#
####################
## set variables  ##
####################
version="v2.0"
scriptlong=`basename "$0"` # imports the name of this script
lockname=${scriptlong::-3} # reduces the name to remove .sh
logname=$lockname.log # Uses the script name to create the log
config_file="$HOME/.config/ScriptSettings/sync_config.sh"
stamp=$(echo "SYNC-`date +%d_%m_%Y`-`date +%H.%M.%S`")
stamplog=$(echo "`date +%d%m%Y`-`date +%H_%M_%S`")
dir_name="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#
#
#####################################
## Import sensitive data from file ##
#####################################
#check for config file
if [[ ! -f "$config_file" ]]; then
  echo "config file $config_file does not exist, script exiting"
  exit 1
else
  #source config file
  echo "config file found, using"
  source "$config_file"
fi
#
#
##############################################################
## set FUNCTIONS - tested on KODI 17/18 for library actions ##
##############################################################
update_videolibrary () {
curl --data-binary '{ "jsonrpc": "2.0", "method": "VideoLibrary.Scan", "id": "mybash"}' -H 'content-type: application/json;' $kodi_VIDEO_assembly
}
#
update_musiclibrary () {
curl --data-binary '{ "jsonrpc": "2.0", "method": "AudioLibrary.Scan", "id": "mybash"}' -H 'content-type: application/json;' $kodi_MUSIC_assembly
}
#
clean_videolibrary () {
curl --data-binary '{ "jsonrpc": "2.0", "method": "VideoLibrary.Clean", "id": "mybash"}' -H 'content-type: application/json;' $kodi_VIDEO_assembly
}
#
clean_musiclibrary () {
curl --data-binary '{ "jsonrpc": "2.0", "method": "AudioLibrary.Clean", "id": "mybash"}' -H 'content-type: application/json;' $kodi_MUSIC_assembly
}
#
rsync_error_catch () {
  if [ $? == "0" ]
   then
    echo "`date +%d/%m/%Y` - `date +%H:%M:%S` $section rsync completed successfully" >> $logfolder/$logname
   else
    echo "`date +%d/%m/%Y` - `date +%H:%M:%S` $section produced an error" >> $logfolder/$logname
  fi
}
#
#
#######################
## Start Main Script ##
#######################
mkdir -p "$logfolder"
echo "#####################################################################################################################" > $logfolder/$logname
echo " - $scriptlong Started, sleeping for 1min to allow network to start" >> $logfolder/$logname
echo "User is $username and config file is $config_file" >> $logfolder/$logname #for error checking
sleep 15s #sleep for cron @reboot to allow tine for network to start
#
#
################
## MUSIC sync ##
################
section="music_sync"
if [[ "$section" -eq 1 ]]
then
  echo "-------------------------------------------------------------------------------------" >> $logfolder/$logname
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MUSIC sync SELECTED, sync started" >> $logfolder/$logname
  rsync "$rsync_prune_empty" "$rsync_set_perms" "$rsync_set_OwnGrp" "$rsync_set_chmod" "$rsync_set_chown" "$rsync_protect_args" "$rsync_remove_source" "$rsync_vzrc" "$downloadbox_user"@"$downloadbox_ip":"$lossless_source" "$lossless_dest" >> $logfolder/$logname
  rsync_error_catch
  "$dir_name"/MusicSync.sh #run seperate 'tagger' script
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MUSIC sync finished" >> $logfolder/$logname
else
  echo "-------------------------------------------------------------------------------------" >> $logfolder/$logname
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MUSIC sync DESELECTED, no sync" >> $logfolder/$logname
fi
#
#
###############
## FILM sync ##
###############
section="movies"
if [[ "section" -eq 1 ]]
then
  echo "-------------------------------------------------------------------------------------" >> $logfolder/$logname
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MOVIES sync SELECTED, sync started" >> $logfolder/$logname
  rsync "$rsync_prune_empty" "$rsync_set_perms" "$rsync_set_OwnGrp" "$rsync_set_chmod" "$rsync_set_chown" "$rsync_protect_args" "$rsync_remove_source" "$rsync_vzrc" "$downloadbox_user"@"$downloadbox_ip":"$movie_source" "$movie_dest" >> $logfolder/$logname
  rsync_error_catch
  update_videolibrary # update Video Library on Kodi Video Server
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MOVIES sync COMPLETE" >> $logfolder/$logname
else
  echo "-------------------------------------------------------------------------------------" >> $logfolder/$logname
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MOVIES sync DESELECTED, no sync" >> $logfolder/$logname
fi
#
#
#############
## TV sync ##
#############
section="tv"
if [[ "$section" -eq 1 ]]
then
  echo "------------------------------------------------------------------------------------" >> $logfolder/$logname
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - TV sync SELECTED, sync started" >> $logfolder/$logname
  rsync "$rsync_prune_empty" "$rsync_set_perms" "$rsync_set_OwnGrp" "$rsync_set_chmod" "$rsync_set_chown" "$rsync_protect_args" "$rsync_remove_source" "$rsync_vzrc" "$downloadbox_user"@"$downloadbox_ip":"$tv_source" "$tv_dest" >> $logfolder/$logname
  rsync_error_catch
  update_videolibrary # update Video Library on Kodi Video Server
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - TV sync finished" >> $logfolder/$logname
else
  echo "-------------------------------------------------------------------------------------" >> $logfolder/$logname
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - TV sync DESELECTED, no sync" >> $logfolder/$logname
fi
#
#
####################
## start NFL sync ##
####################
section="nfl"
if [[ "$section" -eq 1 ]]
then
  echo "------------------------------------------------------------------------------------" >> $logfolder/$logname
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - NFL sync SELECTED, sync started" >> $logfolder/$logname
  rsync "$rsync_prune_empty" "$rsync_protect_args" "$rsync_vzrc" "$downloadbox_user"@"$downloadbox_ip":"$nfl_source" "$nfl_dest" >> $logfolder/$logname
  rsync_error_catch
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - NFL sync finished" >> $logfolder/$logname
else
  echo "-------------------------------------------------------------------------------------" >> $logfolder/$logname
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - NFL sync DESELECTED, no sync" >> $logfolder/$logname
fi
#
echo "------------------------------------------------------------------------------------" >> $logfolder/$logname
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - $scriptlong complete" >> $logfolder/$logname
#
#
echo "#####################################################################################################################" > $logfolder/$logname
exit 0
