#!/usr/bin/env bash
#
#
####################################################################################################
## this script is to move downloaded media from raspberry pi
## it moves media from the pi to media pc using an rsync pull
## script is in user bin folder but run from sudo or su cron not user
##
##
## transmission downloads movies to:
## /media/pi/USBSTORAGE/downloads/completed/transmission/movies
## and tv shows to:
## /media/pi/USBSTORAGE/downloads/completed/transmission/tv
##
##
## then nzbToMedia script TorrentToMedia processes the files on completion and moves...
## ...movies from:
## /media/pi/USBSTORAGE/downloads/completed/transmission/movies
## to:
## /media/pi/USBSTORAGE/downloads/completed/movies
##
##
##  ...TV from:
## /media/pi/USBSTORAGE/downloads/completed/trasmission/tv
## to:
## /media/pi/USBSTORAGE/downloads/completed/tv
##
##
## CouchPotato renames and moves the files from:
## /media/pi/USBSTORAGE/downloads/completed/movies
## to:
## /media/pi/USBSTORAGE/Movies
##
##
## SickRage renames and moves the files from:
## /media/pi/USBSTORAGE/downloads/completed/tv
## to:
## /media/pi/USBSTORAGE/TV
####################################################################################################
#
###################################
# Import sensitive data from file #
###################################
#
source ./config.sh
#
#
####################
## set variables  ##
####################
#
losslessmusicsource=/mnt/usbstorage/music/
losslessmusicdest=/home/jlivin25/Music/DownloadTransfers/
tvsource=/mnt/usbstorage/tv/
tvdest=/media/Data_1/"James' Files"/"My Videos"/"TV Series"
nflsource=/mnt/usbstorage/download/complete/transmission/nfl/
nfldest=/home/jlivin25/"TV Shows"/NFL
moviesource=/mnt/usbstorage/movies/
moviedest=/media/Data_1/"James' Files"/"My Videos"/"HD Films"
locknamelong=`basename "$0"`    			# imports the name of this script
lockname=${locknamelong::-3}    			# reduces the name to remove .sh
logfolder=/home/jlivin25/bin/myscripts/scriptlogs/      # Where the logs are kept
logname=$lockname.log  					# Uses the script name to create the log
rswit=-vzrc						# switchs for rsync, stopped using 'a' so as to use umask 
umaskset=0000						# Umask for 777 perms is 0000
kodilocal=http://$kodiuser:$kodipass@192.168.0.2:8080/jsonrpc
#KODI 17/18 - Krypton Functions for library actions
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
# add sleep for cron @reboot to allow tine for network to start
sleep 1m
#
#
#
################################################################################################################################################################
# start MUSIC sync
echo "----------------------------------------------------" >> $logfolder/$logname
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Music sync started" >> $logfolder/$logname
# sync flac source files first
umask $umaskset
rsync --protect-args --remove-source-files -vzrc pi@192.168.0.18:"$losslessmusicsource" "$losslessmusicdest" >> $logfolder/$logname
sleep 1
/home/jlivin25/bin/myscripts/MusicSync.sh
#update music library on Kodi
update_musiclibrary
sleep 1
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Music sync finished" >> $logfolder/$logname
################################################################################################################################################################
#
#
#
#
################################################################################################################################################################
# start FILM sync next
echo "----------------------------------------------------" >> $logfolder/$logname
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Film sync started" >> $logfolder/$logname
umask $umaskset
rsync --protect-args --remove-source-files -vzrc pi@192.168.0.18:"$moviesource" "$moviedest" >> $logfolder/$logname
# update Video Library on Kodi
sleep 1
update_videolibrary
sleep 1
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - Movie sync finished" >> $logfolder/$logname
################################################################################################################################################################
#
#
#
#
################################################################################################################################################################
# start TV downloads sync
echo "----------------------------------------------------" >> $logfolder/$logname
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - TV sync started" >> $logfolder/$logname
umask $umaskset
rsync --protect-args --remove-source-files -vzrc pi@192.168.0.18:"$tvsource" "$tvdest" >> $logfolder/$logname
# add sleep
sleep 1
# update Video Library on Kodi
update_videolibrary
sleep 1
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - TV sync finished" >> $logfolder/$logname
################################################################################################################################################################
#
#
#
#
################################################################################################################################################################
# start NFL downloads sync
echo "----------------------------------------------------" >> $logfolder/$logname
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - NFL sync started" >> $logfolder/$logname
umask $umaskset
rsync --protect-args -vzrc pi@192.168.0.18:"$nflsource" "$nfldest" >> $logfolder/$logname
# add sleep
sleep 1
# update Video Library on Kodi
update_videolibrary
sleep 1
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - NFL sync finished" >> $logfolder/$logname
################################################################################################################################################################
#
#
# one more time for luck
update_videolibrary
update_musiclibrary
# end
echo "----------------------------------------------------" >> $logfolder/$logname
echo "`date +%d/%m/%Y` - `date +%H:%M:%S` - $locknamelong complete" >> $logfolder/$logname
exit 0

