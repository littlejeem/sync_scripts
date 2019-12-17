########################
## "Global Settings" ###
########################
user="" #user who will be running the script
rsync_path="/usr/bin/rsync" #default destination set, change as appropriate
rsync_variable1="--protect-args" #default destination set, change as appropriate
rsync_variable2="--remove-source-files" #default destination set, change as appropriate
rsync_switch="-vzrc" #set to -vzrc by default, only change if you know what you are doing
logfolder="/home/"$user"/scripts/scriptlogs"
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
## "Kodi Config" ###
####################
kodiuser="" #username ofthe kodi interface on the local machine
kodipass="" #password of same
PORT="" #port that kodi is running under, usually 8080
KODIASSEMBLY="http://"$kodiuser":"$kodipass"@"$LOCAL_IP":"$PORT"/jsonrpc" #auto generated for curl from other variables
#
#
####################
## "Sync Choices" ##
####################
MUSIC="0" #1 to include, 0 to ignore. 0 is set as default
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
#Umask
umask_syncmedia="" #umask set prior to an rsync, 0000 is the default for 777 equiv permissions
#############################
## "MusicSync.sh Settings" ##
#############################
# Music Sources
download_flac="" #FLAC Files from Lidarr transferred via rsync to media pc
rip_flac="" #FLAC files ripped from CD by rippng script on media pc
alaclibrary_source="" #Beets library location where the FLAC files are converted to M4A and placed
flaclibrary_source="" #Beets library location where the FLAC files are tagged and moved too
upload_mp3="" #Beets library where the mp3 uploads are stored
# Music Destinations
FLAC_musicdest="" #where the FLAC files are stored
M4A_musicdest="" #where the M4A files are stored
# Beets
beets_path="/home/$user/.local/bin/beet" #default destination set change as appropriate
beets_switch=""
beets_flac_path="" #path to beets config & library file directory (FLAC)
beets_alac_path="" #path to beets config & library file directory (alac)
beets_upload_path="" #path to beets config & library file directory (upload)
#
#
###########################
### "Pushover" Settings ###
###########################
app_token=""
user_token=""
#
#
