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
version="3.1"


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

rsync_error_catch () {
  if [ $? == "0" ]
   then
    einfo "rsync completed successfully"
   else
    eerror "rsync produced an error"
    rsync_error_flag="y"
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
#check_source
#if [ "$test_flac_down" = "n" ] && [ "$test_flac_rip" = "n" ]; then
#  enotify "no input files detected, exiting"
#  clean_exit
#else
#  edebug "test_flac_down set as: $test_flac_down, test_flac_rip set as: $test_flac_rip"
#  einfo "...checks complete, continuing"
#fi

shopt -s nullglob #here to prevent globbing of names in arrays that contain spaces
edebug "Grabbing contents of $download_flac into array"
download_flac_array=("$download_flac"*)
edebug "array contents are: ${download_flac_array[*]}"
download_flac_array_count=${#download_flac_array[@]} #counts the number of elements in the array and assigns to the variable 'download_flac_array_count'
edebug "found: $download_flac_array_count folder(s)"
if [[ "$download_flac_array_count" -gt 0 ]]; then
  edebug "source: $download_flac_array contains valid content, processing..."
  for (( i=0; i<$download_flac_array_count; i++)); do #basically says while the count (starting from 0) is less than the value in download_names do the next bit
    edebug "...artist folder: ${download_flac_array[$i]}"
    #+-----------------------------+
    #+---"$download_flac import"---+
    #+-----------------------------+
    beets_import_result=$(/home/jlivin25/.local/bin/beet -c /home/jlivin25/.config/beets/flac/flac_convert_config.yaml import -q "${download_flac_array[$i]}")
    edebug "beets import result is as: $beets_import_result"
    if $(echo "$beets_import_result" | grep -q "Skipping") ; then
        edebug "detected beets skipping import of ${download_flac_array[i]}"
        edebug "moving skipped import to $skipped_imports_location"
        if [[ -d "${download_flac_array[i]}" ]]; then
          #mv ${download_flac_array[i]} "$skipped_imports_location"/
          edebug "adding ${download_flac_array[i]} to skipped_imports_array"
          skipped_imports_array+=(${download_flac_array[i]}) #append download_flac_array element 'i' to skipped_import_array
          edebug "skipped_imports_array contents are: ${skipped_imports_array[*]}"
        fi
        rm ~/.config/beets/flac/musiclibrary.blb
    else
      edebug "beets successfully imported: ${download_flac_array[i]}", converting...
      /home/jlivin25/.local/bin/beet -c /home/jlivin25/.config/beets/flac/flac_convert_config.yaml convert -f alac -y -a
      rm ~/.config/beets/flac/musiclibrary.blb
    fi
  done
else
  edebug "No folders found in: $download_flac"
fi

#use above to scan folders download_flac & rip_flac for files -> If they exist process them
#Step 1: tag and move, Step 2: Convert while copying. Step 1 avoids the capture of what worked and what didn't because beets only moves files if import is successful
#1: Import using the cusomised config, we use the 'move' option as if the import is successful it moves the flac files out of the original source directory
#/home/jlivin25/.local/bin/beet -c /home/jlivin25/.config/beets/flac/flac_convert_config.yaml import -q /home/jlivin25/Music/Downloads/
#2: Create a converted copy via
#/home/jlivin25/.local/bin/beet -c /home/jlivin25/.config/beets/flac/flac_convert_config.yaml convert -f alac -y -a
#delete the library and then do rip_flac same way
#rm ~/.config/beets/flac/musiclibrary.blb



#/home/jlivin25/.local/bin/beet -c /home/jlivin25/.config/beets/flac/flac_convert_config.yaml import -q /home/jlivin25/Music/Rips/
#2: Create a converted copy via
#/home/jlivin25/.local/bin/beet -c /home/jlivin25/.config/beets/flac/flac_convert_config.yaml convert -f alac -y -a
#delete the library and then do rip_flac same way
#rm ~/.config/beets/flac/musiclibrary.blb



#see if you can read the results and if folders don't successfulyl scan read into 'beets_import_failure' array
#rename those folders
#check for rsync success
#check new folders from array exist in destination
#then delete source
#use same again to

#how to pick out result of this?
#
#/home/jlivin25/Music/Downloads/Imagine Dragons/Mercury – Acts 1 & 2/Digital Media 01 (28 items)
#Skipping.

#/home/jlivin25/Music/Downloads/Imagine Dragons/Mercury – Acts 1 & 2/Digital Media 02 (36 items)
#Skipping.
#

#+------------------------+
#+---"$rip_flac import"---+
#+------------------------+



#+----------------------+
#+---"Starting rsync"---+
#+----------------------+



#+------------+
#+---"Exit"---+
#+------------+
clean_exit
