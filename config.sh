####################
## "Kodi Config" ###
####################
#
#
kodiuser="" #username ofthe kodi interface on the local machine
kodipass="" #password of same
PORT="" #port that kodi is running under, usually 8080
#
#
########################
## "Machine Settings" ##
########################
LOCAL_IP="" #IP address of the local system
REMOTE_IP="" #IP address of the remote system
LOCAL_USER="" #username for the rsync local (pull too)
REMOTE_USER="" #username for the rsync remote system (pull from)
#
#
####################
## "Sync Choices" ##
####################
FLACMUSIC="0" #1 to include, 0 to ignore. 0 is set as default
ALACMUSIC="0" #1 to include, 0 to ignore. 0 is set as default
TV="0" #1 to include, 0 to ignore. 0 is set as default
MOVIES="0" #1 to include, 0 to ignore. 0 is set as default
NFL="0" #1 to include, 0 to ignore. 0 is set as default
#
#
######################################
## "syncmediadownloads.sh Settings" ##
######################################
#
# LOSSLESS AUDIO
lossless_source=""
lossless_dest=""
# TV
tv_source=""
tv_dest=""
# MOVIES
movie_source=""
movie_dest=""
# NFL
nfl_source=""
nfl_dest=""
#
#
#############################
## "MusicSync.sh Settings" ##
#############################
# Music Sources
download_flac=/home/jlivin25/Music/DownloadTransfers #FLAC Files from Lidarr transferred via rsync to media pc
rip_flac=/home/jlivin25/Music/RipTransfers #FLAC files ripped from CD by rippng script on media pc
alaclibrary_source=/home/jlivin25/Music/Library/alacimports #Beets library location where the FLAC files are converted to M4A and placed
flaclibrary_source=/home/jlivin25/Music/Library/flacimports #Beets library location where the FLAC files are tagged and moved too
#
# Music Destinations
FLAC_musicdest=/media/Data_1/Music/FLAC_Backups/ #where the FLAC files are stored
M4A_musicdest=/media/Data_1/Music/correct/Albums/ #where the M4A files are stored
# Beets
beets_path=""
beets_switch=""
beets_flac_path="" #path to beets config & library file directory (FLAC)
beets_alac_path="" #path to beets config & libraryfile directory (alac)
