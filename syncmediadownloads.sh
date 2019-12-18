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
VERSION="v2.0"
scriptlong=`basename "$0"` # imports the name of this script
lockname=${scriptlong::-3} # reduces the name to remove .sh
logname=$lockname.log # Uses the script name to create the log
DIR2="$HOME/bin/sync_scripts"
#
#
###################################
# Import sensitive data from file #
###################################
source "$DIR2"/config.sh
#
#
##############################################################
## set FUNCTIONS - tested on KODI 17/18 for library actions ##
##############################################################
update_videolibrary () {
curl --data-binary '{ "jsonrpc": "2.0", "method": "VideoLibrary.Scan", "id": "mybash"}' -H 'content-type: application/json;' $KODIASSEMBLY
}
#
update_musiclibrary () {
curl --data-binary '{ "jsonrpc": "2.0", "method": "AudioLibrary.Scan", "id": "mybash"}' -H 'content-type: application/json;' $KODIASSEMBLY
}
#
clean_videolibrary () {
curl --data-binary '{ "jsonrpc": "2.0", "method": "VideoLibrary.Clean", "id": "mybash"}' -H 'content-type: application/json;' $KODIASSEMBLY
}
#
clean_musiclibrary () {
curl --data-binary '{ "jsonrpc": "2.0", "method": "AudioLibrary.Clean", "id": "mybash"}' -H 'content-type: application/json;' $KODIASSEMBLY
}
#
echo "#####################################################################################################################" > $logfolder/$logname
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - $locknamelong Started, sleeping for 1min to allow network to start" >> $logfolder/$logname
echo "Directory being used is "$DIR2"" >> $logfolder/$logname# for error checking
sleep 1m #sleep for cron @reboot to allow tine for network to start
#
#
##################
### MUSIC sync ###
##################
if [[ "$MUSIC" -eq 1 ]]
then
  echo "-------------------------------------------------------------------------------------" >> $logfolder/$logname
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MUSIC sync SELECTED, sync started" >> $logfolder/$logname
  rsync "$rsync_variable1" "$rsync_variable2" "$rsync_switch" "$REMOTE_USER"@"$REMOTE_IP":"$lossless_source" "$lossless_dest" >> $logfolder/$logname
  "$DIR2"/MusicSync.sh #run seperate 'tagger' script
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MUSIC sync finished" >> $logfolder/$logname
else
  echo "-------------------------------------------------------------------------------------" >> $logfolder/$logname
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MUSIC sync DESELECTED, no sync" >> $logfolder/$logname
fi
#
#
#################
### FILM sync ###
#################
if [[ "$MOVIES" -eq 1 ]]
then
  echo "-------------------------------------------------------------------------------------" >> $logfolder/$logname
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MOVIES sync SELECTED, sync started" >> $logfolder/$logname
  umask "$umask_syncmedia"
  rsync "$rsync_variable1" "$rsync_variable2" "$rsync_switch" "$REMOTE_USER"@"$REMOTE_IP":"$movie_source" "$movie_dest" >> $logfolder/$logname
  update_videolibrary # update Video Library on Kodi
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MOVIES sync COMPLETE" >> $logfolder/$logname
else
  echo "-------------------------------------------------------------------------------------" >> $logfolder/$logname
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MOVIES sync DESELECTED, no sync" >> $logfolder/$logname
fi
#
#
###############
### TV sync ###
###############
if [[ "$TV" -eq 1 ]]
then
  echo "------------------------------------------------------------------------------------" >> $logfolder/$logname
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - TV sync SELECTED, sync started" >> $logfolder/$logname
  umask "$umask_syncmedia"
  rsync "$rsync_variable1" "$rsync_variable2" "$rsync_switch" "$REMOTE_USER"@"$REMOTE_IP":"$tv_source" "$tv_dest" >> $logfolder/$logname
  update_videolibrary # update Video Library on Kodi
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
if [[ "$NFL" -eq 1 ]]
then
  echo "------------------------------------------------------------------------------------" >> $logfolder/$logname
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - NFL sync SELECTED, sync started" >> $logfolder/$logname
  umask "$umask_syncmedia"
  rsync "$rsync_variable1" "$rsync_variable2" "$rsync_switch" "$REMOTE_USER"@"$REMOTE_IP":"$nfl_source" "$nfl_dest" >> $logfolder/$logname
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - NFL sync finished" >> $logfolder/$logname
else
  echo "-------------------------------------------------------------------------------------" >> $logfolder/$logname
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - NFL sync DESELECTED, no sync" >> $logfolder/$logname
fi
#
#
##############################
## start "MUSICSERVER" sync ##
##############################
if [[ "$MUSICSERVER" -eq 1 ]]
then
  echo "------------------------------------------------------------------------------------" >> $logfolder/$logname
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MUSICSERVER sync SELECTED, sync started" >> $logfolder/$logname
  umask "$umask_syncmedia"
  rsync "$rsync_variable1" "$rsync_variable2" "$rsync_switch" "$REMOTE_USER"@"$REMOTE_IP":"$musicserver_source" "$musicserver_dest" >> $logfolder/$logname
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MUSICSERVER sync finished" >> $logfolder/$logname
else
  echo "-------------------------------------------------------------------------------------" >> $logfolder/$logname
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - MUSICSERVER sync DESELECTED, no sync" >> $logfolder/$logname
fi
#
#
echo "------------------------------------------------------------------------------------" >> $logfolder/$logname
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - $locknamelong complete" >> $logfolder/$logname
echo "####################################################################################" >> $logfolder/$logname
#
#
exit 0
