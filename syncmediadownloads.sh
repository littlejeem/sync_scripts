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
VERSION="v1.0"
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
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Music sync SELECTED, sync started" >> $logfolder/$logname
  "$DIR2"/MusicSync.sh #run seperate 'tagger' script
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Music sync finished" >> $logfolder/$logname
else
  echo "-------------------------------------------------------------------------------------" >> $logfolder/$logname
  echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Music sync DESELECTED, no sync" >> $logfolder/$logname
fi
#
#
#################
### FILM sync ###
#################
echo "-------------------------------------------------------------------------------------" >> $logfolder/$logname
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Film sync started" >> $logfolder/$logname
umask "$umask_syncmedia"
rsync "$rsync_variable1" "$rsync_variable2" "$rsync_switch" "$REMOTE_USER"@"$REMOTE_IP":"$movie_source" "$movie_dest" >> $logfolder/$logname
update_videolibrary # update Video Library on Kodi
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Movie sync finished" >> $logfolder/$logname
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
echo "------------------------------------------------------------------------------------" >> $logfolder/$logname
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - NFL sync started" >> $logfolder/$logname
umask "$umask_syncmedia"
rsync "$rsync_variable1" "$rsync_variable2" "$rsync_switch" "$REMOTE_USER"@"$REMOTE_IP":"$nfl_source" "$nfl_dest" >> $logfolder/$logname
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - NFL sync finished" >> $logfolder/$logname
echo "------------------------------------------------------------------------------------" >> $logfolder/$logname
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - $locknamelong complete" >> $logfolder/$logname
#
#
exit 0
