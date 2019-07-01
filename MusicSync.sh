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
DIR2=${PWD}
source "$DIR2"/config.sh
#
######################
## Define Functions ##
######################
#
# clean Audiolibrary
clean_KodiAudio () {
curl --data-binary '{ "jsonrpc": "2.0", "method": "AudioLibrary.Clean", "id": "mybash"}' -H 'content-type: application/json;' $KODIASSEMBLY
}
# update AudioLibrary
update_KodiAudio () {
curl --data-binary '{ "jsonrpc": "2.0", "method": "AudioLibrary.Scan", "id": "mybash"}' -H 'content-type: application/json;' $KODIASSEMBLY
}
#
#######################
## Start Main Script ##
#######################
#
#
# start MUSIC Import
# convert flacs to alac and copy to the alac library imports first by using -c flag to specify an alternative config to merge
"$beets_path" "$beets_switch" "$beets_alac_path"/config.yaml import -q "$download_flac"
rm "$beets_alac_path"/musiclibrary.blb
"$beets_path" "$beets_switch" "$beets_alac_path"/config.yaml import -q "$rip_flac"
rm "$beets_alac_path"/musiclibrary.blb
# correct the flac file tags now and move to the flac import library using -c flac to specify an alternative config to merge
"$beets_path" "$beets_switch" "$beets_flac_path"/config.yaml import -q "$download_flac"
rm "$beets_flac_path"/musiclibrary.blb
"$beets_path" "$beets_switch" "$beets_flac_path"/config.yaml import -q "$rip_flac"
rm "$beets_flac_path"/musiclibrary.blb
#
# sync tagged flac files next
cd "$flaclibrary_source"
DIR=${PWD}
if [ ! "$(ls -A "$DIR")" ]
then
    echo ""$DIR" is empty, no action"
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
    update_KodiAudio
    sleep 5s
    clean_KodiAudio
    sleep 5s
fi
# all done
exit
