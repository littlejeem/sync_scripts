#!/usr/bin/env bash
#
#
#############################################################################################
## this script is to import music transferred from the raspberry Pi into Beets Librtary   ###
## Once imported and converted it moves the fies to my music library                      ###
## script is in $HOME/bin folder                                                          ###
#############################################################################################
#
###################################
# Import sensitive data from file #
###################################
#
source /home/$user/scripts/controls_cripts/config.sh
#
####################
## set variables  ##
####################
#
#
# Music Sources
download_flac=/home/jlivin25/Music/DownloadTransfers #FLAC Files from Lidarr transferred via rsync to media pc
rip_flac=/home/jlivin25/Music/RipTransfers #FLAC files ripped from CD by rippng script on media pc
alaclibrary_source=/home/jlivin25/Music/Library/alacimports #Beets library location where the FLAC files are converted to M4A and placed
flaclibrary_source=/home/jlivin25/Music/Library/flacimports #Beets library location where the FLAC files are tagged and moved too
#
# Music Destinations
FLAC_musicdest=/media/Data_1/Music/FLAC_Backups/ #where the FLAC files are stored
M4A_musicdest=/media/Data_1/Music/correct/Albums/ #where the M4A files are stored
#
######################
## Define Functions ##
######################
#
# clean Audiolibrary
clean_KodiAudio () {
curl --data-binary '{ "jsonrpc": "2.0", "method": "AudioLibrary.Clean", "id": "mybash"}' -H 'content-type: application/json;' http://"$kodiuser":"$kodipass"@"$SERVER":"$PORT"/jsonrpc
}
# update AudioLibrary
update_KodiAudio () {
curl --data-binary '{ "jsonrpc": "2.0", "method": "AudioLibrary.Scan", "id": "mybash"}' -H 'content-type: application/json;' http://"$kodiuser":"$kodipass"@"$SERVER":"$PORT"/jsonrpc
}
#
#######################
## Start Main Script ##
#######################
#
# clean Kodi AudioLibrary
clean_KodiAudio
#
# start MUSIC Import
#
# convert flacs to alac and copy to the alac library imports first by using -c flag to specify an alternative config to merge
/home/jlivin25/.local/bin/beet -c /home/jlivin25/.config/beets/alac/config.yaml import -q $download_flac
rm /home/jlivin25/.config/beets/alac/musiclibrary.blb
sleep 5s
/home/jlivin25/.local/bin/beet -c /home/jlivin25/.config/beets/alac/config.yaml import -q $rip_flac
rm /home/jlivin25/.config/beets/alac/musiclibrary.blb
sleep 5s
# correct the flac file tags now and move to the flac import library using -c flac to specify an alternative config to merge
/home/jlivin25/.local/bin/beet -c /home/jlivin25/.config/beets/flac/config.yaml import -q $download_flac
rm /home/jlivin25/.config/beets/flac/musiclibrary.blb
sleep 5s
/home/jlivin25/.local/bin/beet -c /home/jlivin25/.config/beets/flac/config.yaml import -q $rip_flac
rm /home/jlivin25/.config/beets/flac/musiclibrary.blb
sleep 5s
#
# sync tagged flac files next
cd $flaclibrary_source
DIR=$PWD
if [ ! "$(ls -A "$DIR")" ]
then
    echo "$DIR is empty, no action"
else
    echo "$DIR is not empty, copying then deleting files"
    sleep 5s
    cp -rpv $flaclibrary_source/* $FLAC_musicdest
    rm -r *
fi
#
#
# sync alac music files next
cd $alaclibrary_source
DIR=$PWD
if [ ! "$(ls -A "$DIR")" ]
then
    echo "$DIR is empty, no action"
else
    echo "$DIR is not empty, copying then deleting files"
    sleep 5s
    cp -rpv $alaclibrary_source/* $M4A_musicdest
    rm -r *
    update_KodiAudio
    sleep 5s
    clean_KodiAudio
    sleep 5s
fi
# all done
exit
