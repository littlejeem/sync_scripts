#!/usr/bin/env bash
#
#############################################################################################
## this script is to move downloaded media from a remote source, such as raspberry pi,     ##
## it moves media from the remote to the media source (local machine) using an rsync pull  ##
## script is in user bin folder but run from sudo or su cron not user                      ##
#############################################################################################
#
#
###################################
# Import sensitive data from file #
###################################
source .config.sh
#
#
####################
## set variables  ##
####################
scriptlong=`basename "$0"` # imports the name of this script
lockname=${scriptlong::-3} # reduces the name to remove .sh
logname=$lockname.log # Uses the script name to create the log
#
#
##############################################################
## set FUNCTIONS - tested on KODI 17/18 for library actions ##
##############################################################
update_videolibrary () {
curl --data-binary '{ "jsonrpc": "2.0", "method": "VideoLibrary.Scan", "id": "mybash"}' -H 'content-type: application/json;' $kodilocal
}
#
update_musiclibrary () {
curl --data-binary '{ "jsonrpc": "2.0", "method": "AudioLibrary.Scan", "id": "mybash"}' -H 'content-type: application/json;' $kodilocal
}
#
clean_videolibrary () {
curl --data-binary '{ "jsonrpc": "2.0", "method": "VideoLibrary.Clean", "id": "mybash"}' -H 'content-type: application/json;' $kodilocal
}
#
clean_musiclibrary () {
curl --data-binary '{ "jsonrpc": "2.0", "method": "AudioLibrary.Clean", "id": "mybash"}' -H 'content-type: application/json;' $kodilocal
}
#
echo "----------------------------------------------------" > $logfolder/$logname
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - $locknamelong Started, sleeping for 3mins to allow network to start" >> $logfolder/$logname
sleep 1m #sleep for cron @reboot to allow tine for network to start
#
#
######################
## start MUSIC sync ##
######################
echo "----------------------------------------------------" >> $logfolder/$logname
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Music sync started" >> $logfolder/$logname
# sync flac source files first
umask $umask_syncmedia
rsync "$rsync_variable1" "$rsync_variable2" "$rsync_switch" "$REMOTE_USER"@"$REMOTE_IP":"$lossless_source" "$lossless_dest" >> $logfolder/$logname
/home/jlivin25/bin/myscripts/MusicSync.sh
update_musiclibrary #update music library on Kodi
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Music sync finished" >> $logfolder/$logname
#
#
#####################
## start FILM sync ##
#####################
echo "----------------------------------------------------" >> $logfolder/$logname
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Film sync started" >> $logfolder/$logname
umask $umask_syncmedia
rsync "$rsync_variable1" "$rsync_variable2" "$rsync_switch" "$REMOTE_USER"@"$REMOTE_IP":"$movie_source" "$movie_dest" >> $logfolder/$logname
update_videolibrary # update Video Library on Kodi
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Movie sync finished" >> $logfolder/$logname
#
#
###################
## start TV sync ##
###################
echo "----------------------------------------------------" >> $logfolder/$logname
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - TV sync started" >> $logfolder/$logname
umask $umask_syncmedia
rsync "$rsync_variable1" "$rsync_variable2" "$rsync_switch" "$REMOTE_USER"@"$REMOTE_IP":"$tv_source" "$tv_dest" >> $logfolder/$logname
update_videolibrary # update Video Library on Kodi
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - TV sync finished" >> $logfolder/$logname
#
#
####################
## start NFL sync ##
####################
echo "----------------------------------------------------" >> $logfolder/$logname
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - NFL sync started" >> $logfolder/$logname
umask $umask_syncmedia
rsync "$rsync_variable1" "$rsync_variable2" "$rsync_switch" "$REMOTE_USER"@"$REMOTE_IP":"$nfl_source" "$nfl_dest" >> $logfolder/$logname
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - NFL sync finished" >> $logfolder/$logname
echo "----------------------------------------------------" >> $logfolder/$logname
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - $locknamelong complete" >> $logfolder/$logname
echo "----------------------------------------------------" >> $logfolder/$logname
#
#
exit 0
