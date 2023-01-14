#!/usr/bin/env bash


#################################################################################################
## "INFO"                                                                                      ##
## This script is to import music transferred from the a remote location into Beets Library    ##
## Once imported and converted it moves the fies to my music storage, this is also done with   ##
## any ripped music                                                                            ##
##                                                                                             ##
## "REQUIREMENTS"                                                                              ##
## Requires bin/control_scripts/control_scripts_install.sh running to prep environment         ##
##                                                                                             ##
## "LOCATION"                                                                                  ##
## script is in $HOME/bin/sync_cripts                                                          ##
#################################################################################################
#
#+-----------------+
#+---Set Version---+
#+-----------------+
version="2.2"


#+---------------------+
#+---"Set Variables"---+
#+---------------------+
scriptlong="MusicSync.sh" # imports the name of this script
lockname=${scriptlong::-3} # reduces the name to remove .sh
script_pid=$(echo $$)

#set default logging level
verbosity=3


#+--------------------------------------+
#+---"Exit Codes & Logging Verbosity"---+
#+--------------------------------------+
# pick from 64 - 113 (https://tldp.org/LDP/abs/html/exitcodes.html#FTN.AEN23647)
# exit 0 = Success
# exit 64 = Variable Error
# exit 65 = Sourcing file/folder error
# exit 66 = Processing Error
# exit 67 = Required Program Missing
#
#verbosity levels
#silent_lvl=0
#crt_lvl=1
#err_lvl=2
#wrn_lvl=3
#ntf_lvl=4
#inf_lvl=5
#dbg_lvl=6


#+--------------------------+
#+---Source helper script---+
#+--------------------------+
PATH=/sbin:/bin:/usr/bin:/home/jlivin25:/home/jlivin25/.local/bin:/home/jlivin25/bin
source /usr/local/bin/helper_script.sh


#+---------------------------------------+
#+---"check if script already running"---+
#+---------------------------------------+
check_running


#+------------------------+
#+--- Define Functions ---+
#+------------------------+
clean_ctrlc () {
  let ctrlc_count++
  echo
  if [[ $ctrlc_count == 1 ]]; then
    echo "Quit command detected, are you sure?"
  elif [[ $ctrlc_count == 2 ]]; then
    echo "...once more and the script will exit..."
  else
    clean_exit
  fi
}

clean_exit () {
  edebug "Exiting script gracefully"
  rm -r /tmp/music_converter_in_progress_block
  rm -r /tmp/"$lockname"
  esilent "MusicSync.sh completed successfully"
  exit 0
}

fatal_missing_var () {
 if [ -z "${JAIL_FATAL}" ]; then
  ecrit "Failed to find: $JAIL_FATAL, JAIL_FATAL is unset or set to the empty string, script cannot continue. Exiting!"
  rm -r /tmp/"$lockname"
  exit 64
 else
  einfo "variable found, using: $JAIL_FATAL"
 fi
}

debug_missing_var () {
 if [ -z "${JAIL_DEBUG}" ]; then
  edebug "JAIL_DEBUG $JAIL_DEBUG is unset or set to the empty string, may cause issues"
 else
  einfo "variable found, using: $JAIL_DEBUG"
 fi
}

beets_function () {
 einfo "$section processing started"
# shellcheck source=../sync_config.sh
 if find "$download_flac" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
  einfo "files located in $download_flac"
  OUTPUT=$("$beets_path" "$beets_switch" "$beets_config_path"/"$config_yaml" import -q "$download_flac")
  timestamp=$(date +%a%R)
  echo "$OUTPUT" | grep "Skipping"
  if [[ $? = 0 ]]; then
    edebug "detected beets skipping"
    unknown_artist="$rip_flac""Unknown Artist"
    edebug "Unknown Artist path is: $unknown_artist"
    edebug "Generic 'Unknown Artist' folder, assuming non tagging by beets, keeping folder appended with timestamp"
    mv "$unknown_artist" "$unknown_artist""-$timestamp"
  fi
  rm "$beets_config_path"/musiclibrary.blb
  should_sync="y"
 else
  einfo "$download_flac is empty, no conversion needed"
 fi
 if find "$rip_flac" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
  einfo "files located in $rip_flac"
  OUTPUT=$("$beets_path" "$beets_switch" "$beets_config_path"/"$config_yaml" import -q "$rip_flac")
  timestamp=$(date +%a%R)
  echo "$OUTPUT" | grep "Skipping"
  if [[ $? = 0 ]]; then
    edebug "detected beets skipping"
    unknown_artist="$rip_flac""Unknown Artist"
    edebug "$unknown_artist"
    edebug "Generic 'Unknown Artist' folder, assuming non tagging by beets, keeping folder appended with timestamp"
    mv "$unknown_artist" "$unknown_artist""-$timestamp"
  fi
  rm "$beets_config_path"/musiclibrary.blb
  should_sync="y"
 else
  einfo "$rip_flac is empty, no conversion needed"
 fi
 einfo "$section processing finished"
}

rsync_error_catch () {
  if [ $? == "0" ]
   then
    einfo "rsync completed successfully"
   else
    eerror "rsync produced an error"
    rsync_error_flag="y"
  fi
}

delete_function () {
  sleep "$sleep_time"
  find "$location" -mindepth 1 -maxdepth 1 -type d -not -wholename ""$location"Unknown\ Artist-*" -prune -exec echo '{}' \;
  sleep "$sleep_time"
  find "$location" -mindepth 1 -maxdepth 1 -type d -not -wholename ""$location"Unknown\ Artist-*" -prune -exec rm -rf '{}' \;
}

Logic1 () {
  if [ "$test_flac_down" = "y" ] || [ "$test_flac_rip" = "y" ] && [ -z "$rsync_error_flag" ]; then
    find "$location2" -mindepth 1 -print -quit 2>/dev/null | grep -q . #<---Command above returns 0 for contents found, or 1 if nothing found
    if [[ "$?" = "0" ]]; then
      einfo "Test conditions met, I am deleting..."
      location="$download_flac"
      delete_function
      location="$rip_flac"
      delete_function
      location="$location2"
      if [ -z "$location2" ]; then
       edebug "No second delete location set"
      else
       delete_function
      fi
    else
      ewarn "Test codition not met, found files in $download_flac or $rip_flac but none in $location2, possible failed conversion"
      clean_exit
    fi
  else
    eerror "Expected files in $download_flac or $rip_flac and no rsync errors, one of these conditions failed"
    clean_exit
  fi
}

check_source () {
  find "$download_flac" -mindepth 1 -print -quit 2>/dev/null | grep -q . #<---Command above returns 0 for contents found, or 1 if nothing found
  if [[ "$?" = "0" ]]; then
    einfo "Located files in directory $download_flac"
    test_flac_down="y"
  else
    einfo "no files located in directory $download_flac"
    test_flac_down="n"
  fi
  find "$rip_flac" -mindepth 1 -print -quit 2>/dev/null | grep -q . #<---Command above returns 0 for contents found, or 1 if nothing found
  if [[ "$?" = "0" ]]; then
    einfo "Located files in directory $rip_flac"
    test_flac_rip="y"
  else
    einfo "no files located in directory $rip_flac"
    test_flac_rip="n"
  fi
}


helpFunction () {
   echo ""
   echo "Usage: $0 MusicSync.sh"
   echo "Usage: $0 MusicSync.sh -G"
   echo -e "\t Running the script with no flags causes default behaviour with logging level set via 'verbosity' variable"
   echo -e "\t-s Override set verbosity to specify silent log level"
   echo -e "\t-V Override set verbosity to specify Verbose log level"
   echo -e "\t-G Override set verbosity to specify Debug log level"
   echo -e "\t-h Use this flag for help"
   if [ -d "/tmp/$lockname" ]; then
     edebug "removing lock directory"
     rm -r "/tmp/$lockname"
   else
     edebug "problem removing lock directory"
   fi
   exit 1 # Exit script after printing help
}
#
#
#+------------------------+
#+---"Get User Options"---+
#+------------------------+
OPTIND=1
while getopts ":sVGh:" opt
do
    case "${opt}" in
        s) verbosity=$silent_lvl
        edebug "-s specified: Silent mode";;
        V) verbosity=$inf_lvl
        edebug "-V specified: Verbose mode";;
        G) verbosity=$dbg_lvl
        edebug "-G specified: Debug mode";;
        u) user_install=${OPTARG}
        edebug "-u specified: using $chosen_user";;
        h) helpFunction;;
        ?) helpFunction;;
    esac
done
shift $((OPTIND -1))


#+---------------------+
#+---"Trap & ctrl-c"---+
#+---------------------+
trap clean_ctrlc SIGINT
trap clean_exit SIGTERM
ctrlc_count=0


#+-------------------------+
#+---"Configure GETOPTS"---+
#+-------------------------+
if [[ $user_install = "" ]]; then
  install_user="$USER"
  export install_user
else
  install_user=$(echo $user_install)
  export install_user=$(echo $user_install)
fi


#+-------------------+
#+---Initial Setup---+
#+-------------------+
esilent "MusicSync.sh started"
#Grab PID
edebug "MusicSync scripts PID is: $script_pid"
#display version
edebug "Version is: $version"
#display env variable PATH
edebug "PATH is: $PATH"
#Check for existance FFMPEG
if [ ! -d /tmp/music_converter_in_progress_block ]; then
  edebug "Creating sync lock"
  mkdir /tmp/music_converter_in_progress_block
else
  ecrit "/tmp/music_converter_in_progress_block exists, check for already running script"
  clean_exit
fi

einfo "beginning checks..."
if [ -d /tmp/media_sync_in_progress_block ]; then
  ecrit "syncmediadownloads.sh is in progress, quitting..." #Quit because could take a while to complete
  clean_exit
fi

if [ -d /tmp/music_sync_in_progress_block ]; then
  while [ -d /tmp/music_sync_in_progress_block ]; do
    ewarn "sync_music_server is in progress, waiting for it to complete..." #Wait as is a short running script
    sleep 5m
  done
fi

if ! command -v ffmpeg &> /dev/null
then
  eerror "FFMPEG could not be found, script won't function wihout it, try running bin/standalone_scripts/manual_ffmpeg_install.sh or apt install ffmpeg -y"
  exit 67
  clean_exit
else
  einfo "FFMPEG command located, continuing"
fi


# check for config file existance
# the aim here is to have a config_file variable populated in the parent folder, once i work that one out, might need to flip this logic
config_file="/usr/local/bin/config.sh"
#
#Export path now to include ~/.local/bin temporarily, sa this will be picked up on next log-in
export PATH=$PATH:/home/"$USER"/.local/bin
edebug "PATH is set as: $PATH"
#
if [[ ! -f "$config_file" ]]; then
  ewarn "config file $config_file does not appear to exist"
  edebug "attempting to source config file from default location"
  config_file="/usr/local/bin/config.sh"
  if [[ ! -f "$config_file" ]]; then
    ecrit "config file still not located at $config_file, script exiting"
    rm -r /tmp/"$lockname"
    exit 65
  else
    edebug "located default config file at $config_file, continuing"
    source "$config_file"
  fi
else
  # source config file
  edebug "Config file found, using $config_file"
  source "$config_file"
fi
#
# check if beets is intalled
if [[ ! -f "$beets_path" ]]; then
  eerror "a beets install at $beets_path not detected, please install and re-run"
  clean_exit
  exit 67
else
  einfo "Beets install detected, using $beets_path"
fi


#+--------------------------------------------+
#+---Check that necessary variables are set---+
#+--------------------------------------------+
JAIL_FATAL="${music_alac}"
fatal_missing_var
#
JAIL_FATAL="${download_flac}"
fatal_missing_var
#
JAIL_FATAL="${rip_flac}"
fatal_missing_var
#
JAIL_FATAL="${alaclibrary_source}"
fatal_missing_var
#
JAIL_FATAL="${flaclibrary_source}"
fatal_missing_var
#
JAIL_FATAL="${upload_mp3}"
debug_missing_var
#
JAIL_FATAL="${FLAC_musicdest}"
fatal_missing_var
#
JAIL_FATAL="${M4A_musicdest}"
fatal_missing_var
#
JAIL_FATAL="${beets_switch}"
fatal_missing_var
#
JAIL_FATAL="${beets_flac_path}"
fatal_missing_var
#
JAIL_FATAL="${beets_alac_path}"
fatal_missing_var
#
JAIL_FATAL="${beets_upload_path}"
debug_missing_var
#
#
#Check if source folders are empty, if they are bail gracefully, if not continue
check_source
if [ "$test_flac_down" = "n" ] && [ "$test_flac_rip" = "n" ]; then
  enotify "no input files detected, exiting"
  clean_exit
fi

einfo "...checks complete, continuing"
#+---------------------------+
#+---Start Conversion Work---+
#+---------------------------+
# ALAC - convert flacs to alac and copy to the ALAC library imports first by using -c flag to specify an alternative config to merge"
config_yaml="alac_config.yaml"
einfo "config.yaml set as $config_yaml"
beets_config_path=$(echo "$beets_alac_path")
einfo "beets_config_path set as $beets_config_path"
section=${config_yaml::-12}
einfo "section running is $section"
if [[ "$music_alac" -eq 1 ]]
then
  beets_function
  sleep 1s
  edebug "should sync is set to: $should_sync"
  if [[ "$should_sync" == "y" ]]
  then
    einfo "$section sync started"
    rsync "$rsync_prune_empty" "$rsync_alt_vzr" "$alaclibrary_source" "$M4A_musicdest"
    rsync_error_catch
    #musicserver_sync
    # TODO(littlejeem): work on the logic here, currently convert, dump, trigger library update, could we trigger scan specific to the new files?
    einfo "$section sync finished"
  else
    einfo "no $section conversions, so no sync"
  fi
else
  einfo "$section conversion not selected" #<---I think this is the issue with the spurious logging name error
fi
#
# UPLOAD - convert the flac files to mp3 and copy to the UPLOAD directory
config_yaml="uploads_config.yaml"
beets_config_path=$(echo "$beets_upload_path")
section=${config_yaml::-12}
if [[ "$music_google" -eq 1 ]]
then
  beets_function
else
  einfo "$section not selected"
fi
#
# FLAC - correct the flac file tags now and move to the FLAC import library using -c flac to specify an alternative config to merge
config_yaml="flac_config.yaml"
einfo "config.yaml set as $config_yaml"
beets_config_path=$(echo "$beets_flac_path")
einfo "beets_config_path set as $beets_config_path"
section=${config_yaml::-12}
einfo "section running is $section"
if [[ "$music_flac" -eq 1 ]]
then
  beets_function
  sleep 1s
  if [[ "$should_sync" == "y" ]]
  then
    einfo "$section sync started"
    rsync "$rsync_remove_source" "$rsync_prune_empty" "$rsync_alt_vzr" "$flaclibrary_source" "$FLAC_musicdest"
    rsync_error_catch
    einfo "$section sync finished"
  else
    einfo "no $section conversions, so no sync"
  fi
else
  einfo "$section conversion not selected"
fi
#
#+-------------------------------+
#+---Begin deletion constructs---+
#+-------------------------------+
#
# Check if source folders contain files
#
# 1: Check if only ALAC conversion is selected
if [ "$music_alac" = "1" ] && [ "$music_flac" = "0" ] && [ "$music_google" = "0" ]; then
  check_source
  location2="$alaclibrary_source"
  sleep_time="2s"
  Logic1
fi
#
# 2: Check if only FLAC conversion is selected
if [ "$music_alac" = "0" ] && [ "$music_flac" = "1" ] && [ "$music_google" = "0" ]; then
  check_source
  location2="$flaclibrary_source"
  sleep_time="2s"
  Logic1
fi
#
# 3: Check if only MP3 Upload is selected
if [ "$music_alac" = "0" ] && [ "$music_flac" = "0" ] && [ "$music_google" = "1" ]; then
  check_source
  location2="$upload_mp3"
  sleep_time="2s"
  Logic1
fi
#
#
# 4: Check if both ALAC & FLAC are selected
if [ "$music_alac" = "1" ] && [ "$music_flac" = "1" ] && [ "$music_google" = "0" ]; then
  check_source
  location2="$alaclibrary_source"
  sleep_time="2s"
  Logic1
  location3="$flaclibrary_source"
  find "$location3" -mindepth 1 -print -quit 2>/dev/null | grep -q . #<---Command above returns 0 for contents found, or 1 if nothing found
  if [[ "$?" = "0" ]]; then
    location="$location3"
    delete_function
  fi
fi
#
#
# all done
clean_exit
