###################
## Version "2.0" ##
###################
#
#
####################
## "Sync Choices" ##
####################
music_sync="0" #1 to include a transfer from download box to media_server, 0 to ignore. 0 is set as default
musicserver_sync="0" #1 to include a sync from media_server to to music server and update host kodi, 0 to ignore. 0 is set as default
  music_google="0" #1 to upload a .mp3 version to gmusic, 0 to ignore. 0 is set as default
  music_alac="0" #1 to create a lossless M4A files and transfer to Data_1, 0 to ignore. 0 is set as default
  music_flac="0" #1 to move FLAC files to a backup folder on Data_1, 0 to ignore. 0 is set as default
tv="0" #1 to include, 0 to ignore. 0 is set as default
movies="0" #1 to include, 0 to ignore. 0 is set as default
nfl="0" #1 to include, 0 to ignore. 0 is set as default
audiobooks="0" #1 to include, 0 to ignore. 0 is set as default
#
#
########################
## "Global Settings" ###
########################
rsync_path="/usr/bin/rsync" #default destination set, change as appropriate
rsync_protect_args="--protect-args" #default destination set, change as appropriate
rsync_remove_source="--remove-source-files" #default destination set, change as appropriate
rsync_set_perms="-p" #tell rsync you explicitly want to set Directory & File Permissions
rsync_set_OwnGrp="-og" #tell rsync you explicity want to specify the "user" & "group"
rsync_set_chmod="--chmod=Dug+rwx,Fug+rwx,o+rx,o-w" #set the permissions, D=directory, F=file
rsync_set_chown="--chown=$fileowner:$group" #set the ownership
rsync_prune_empty="--prune-empty-dirs" #tell rsync not to transfer 'empty' folders during sync
rsync_vzrc="-vzrc" #set to -vzrc by default, only change if you know what you are doing
rsync_alt_vzr="-vzr"
logfolder="$HOME/bin/logs"
rsync_port="ssh -p 0000" #IN DEVELOPMENT NOT YET IN USE
#
#
########################
## "Machine Settings" ##
########################
mediapc_ip="" #IP address of the local system
downloadbox_ip="" #IP address of the remote system
musicserver_ip="" #username for the rsync remote system (push to)
mediapc_user="" #username for the rsync local (pull too)
downloadbox_user="" #username for the rsync remote system (pull from)
musicserver_user= "" #username for the rsync local (push too)
#
#
####################
## "Kodi Config" ###
####################
# video
kodiVIDEOuser="" #username of the kodi interface on the local machine
kodiVIDEOpass="" #password of same
portVIDEO="" #port that kodi video server is running under, usually 8080
kodi_VIDEO_assembly="http://"$kodiVIDEOuser":"$kodiVIDEOpass"@"$mediapc_ip":"$portVIDEO"/jsonrpc" #auto generated for curl from other variables
# music
kodiMUSICuser="" #username ofthe kodi interface on the music server machine
kodiMUSICpass="" #password of same
portMUSIC="8080" #port that kodi is running under, usually 8080
kodi_MUSIC_assembly="http://"$kodiMUSICuser":"$kodiMUSICpass"@"$musicserver_ip":"$portMUSIC"/jsonrpc" #auto generated for curl from other variables
#
#
######################################
## "syncmediadownloads.sh Settings" ##
######################################
# LOSSLESS AUDIO
lossless_source=""
lossless_dest=""
# MUSICSERVER AUDIO
musicserver_source=""
musicserver_dest=""
# AUDIOBOOKS
audiobook_source=""
audiobook_dest=""
# TV
tv_source=""
tv_dest=""
# MOVIES
movie_source=""
movie_dest=""
# NFL
nfl_source=""
nfl_dest=""
# MUSIC SERVER
$musicserver_source=""
$musicserver_dest=""
# file transfers
fileowner="" #file owner of the files desired on the destination location
groupowner="" #group owner of the files desired on the destination location
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
beets_path="/home/$USER/.local/bin/beet" #default destination set change as appropriate
beets_switch=""
beets_flac_path="" #path to beets config & library file directory (FLAC)
beets_alac_path="" #path to beets config & library file directory (alac)
beets_upload_path="" #path to beets config & library file directory (upload)
#
#
#########################
## "Pushover" Settings ##
#########################
user_token="" #<--Main user key from your pushover account
#
#
#######################
## "Backup" Settings ##
#######################
mount="" #<--Desired mount point
uuid="" #<--UUID of the backup drive
backup_app_token="" #<--Script specific token from pushover, which needs setting up first.
loglocation=""
rsyncsource="" #<--Backup from... (trailing slash for "contents of")
rsyncdestination="" #<--Backup too... (no trailing slash to copy INTO trailing folder)
#
#
