#!/usr/bin/env bash
#
#
#################################################################################################
## This script is to import music transferred from the a remote location into Beets Library    ##
## Once imported and converted it moves the fies to my music library, this is also done with   ##
## any ripped music                                                                            ##
## script is in $HOME/bin/sync_cripts                                                          ##
#################################################################################################
#
#+-----------------+
#+---Set Version---+
#+-----------------+
version="2.0"
#
#
#+---------------------+
#+---"Set Variables"---+
#+---------------------+
scriptlong="MusicSync.sh" # imports the name of this script
lockname=${scriptlong::-3} # reduces the name to remove .sh
script_pid=$(echo $$)
#
#set default logging level
verbosity=4
#
#
#+------------------+
#+---"Exit Codes"---+
#+------------------+
# pick from 64 - 113 (https://tldp.org/LDP/abs/html/exitcodes.html#FTN.AEN23647)
# exit 0 = Success
# exit 64 = Variable Error
# exit 65 = Sourcing file error
# exit 66 = Processing Error
# exit 67 = Required Program Missing
#
#
#+--------------------------+
#+---Source helper script---+
#+--------------------------+
PATH=/sbin:/bin:/usr/bin:/home/jlivin25:/home/jlivin25/.local/bin:/home/jlivin25/bin
source "$HOME"/bin/standalone_scripts/helper_script.sh
#
#
#+---------------------------------------+
#+---"check if script already running"---+
#+---------------------------------------+
check_running
#
#
#+------------------------+
#+--- Define Functions ---+
#+------------------------+
# clean Audiolibrary
#
fatal_missing_var () {
 if [ -z "${JAIL_FATAL}" ]; then
  err_lvl "Failed to find: $JAIL_FATAL, JAIL_FATAL is unset or set to the empty string, script cannot continue. Exiting!"
  rm -r /tmp/"$lockname"
  exit 64
 else
  ntf_lvl "variable found, using: $JAIL_FATAL"
 fi
}
#
debug_missing_var () {
 if [ -z "${JAIL_DEBUG}" ]; then
  deb_lvl "JAIL_DEBUG $JAIL_DEBUG is unset or set to the empty string, may cause issues"
 else
  ntf_lvl "variable found, using: $JAIL_DEBUG"
 fi
}
#
beets_function () {
 ntf_lvl "$section processing started"
# shellcheck source=../sync_config.sh
 if find "$download_flac" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
  ntf_lvl "files located in $download_flac"
  OUTPUT=$("$beets_path" "$beets_switch" "$beets_config_path"/"$config_yaml" import -q "$download_flac")
  timestamp=$(date +%a%R)
  echo "$OUTPUT" | grep "Skipping"
  if [[ $? = 0 ]]; then
    deb_lvl "detected beets skipping"
    unknown_artist="$rip_flac""Unknown Artist"
    deb_lvl "$unknown_artist"
    deb_lvl "Generic 'Unknown Artist' folder, assuming non tagging by beets, keeping folder appended with timestamp"
    mv "$unknown_artist" "$unknown_artist""-$timestamp"
  fi
  rm "$beets_config_path"/musiclibrary.blb
  should_sync="y"
 else
  deb_lvl "$download_flac is empty, no conversion needed"
 fi
 if find "$rip_flac" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
  ntf_lvl "files located in $rip_flac"
  OUTPUT=$("$beets_path" "$beets_switch" "$beets_config_path"/"$config_yaml" import -q "$rip_flac")
  timestamp=$(date +%a%R)
  echo "$OUTPUT" | grep "Skipping"
  if [[ $? = 0 ]]; then
    deb_lvl "detected beets skipping"
    unknown_artist="$rip_flac""Unknown Artist"
    deb_lvl "$unknown_artist"
    deb_lvl "Generic 'Unknown Artist' folder, assuming non tagging by beets, keeping folder appended with timestamp"
    mv "$unknown_artist" "$unknown_artist""-$timestamp"
  fi
  rm "$beets_config_path"/musiclibrary.blb
  should_sync="y"
 else
  deb_lvl "$rip_flac is empty, no conversion needed"
 fi
 ntf_lvl "$section processing finished"
}
#
#
#OLD SINGLE BEETS FUNCTION
old_beets_function () {
 ntf_lvl "$section processing started"
 if find "$download_flac" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
  ntf_lvl "files located in $download_flac"
  "$beets_path" "$beets_switch" "$beets_config_path"/"$config_yaml" import -q "$download_flac"
  rm "$beets_config_path"/musiclibrary.blb
  should_sync="y"
 else
  deb_lvl "$download_flac is empty, no conversion needed"
 fi
 if find "$rip_flac" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
  ntf_lvl "files located in $rip_flac"
  "$beets_path" "$beets_switch" "$beets_config_path"/"$config_yaml" import -q "$rip_flac"
  rm "$beets_config_path"/musiclibrary.blb
  should_sync="y"
 else
  deb_lvl "$rip_flac is empty, no conversion needed"
 fi
 ntf_lvl "$section processing finished"
}
#
rsync_error_catch () {
  if [ $? == "0" ]
   then
    ntf_lvl "rsync completed successfully"
   else
    err_lvl "rsync produced an error"
    rsync_error_flag="y"
  fi
}
#
delete_function () {
  sleep "$sleep_time"
  find "$location" -mindepth 1 -maxdepth 1 -type d -not -wholename ""$location"Unknown\ Artist-*" -prune -exec echo '{}' \;
  sleep "$sleep_time"
  find "$location" -mindepth 1 -maxdepth 1 -type d -not -wholename ""$location"Unknown\ Artist-*" -prune -exec rm -rf '{}' \;
}
#
Logic1 () {
  if [ "$test_flac_down" = "y" ] || [ "$test_flac_rip" = "y" ] && [ -z "$rsync_error_flag" ]; then
    find "$location2" -mindepth 1 -print -quit 2>/dev/null | grep -q . #<---Command above returns 0 for contents found, or 1 if nothing found
    if [[ "$?" = "0" ]]; then
      ntf_lvl "Test conditions met, I am deleting..."
      location="$download_flac"
      delete_function
      location="$rip_flac"
      delete_function
      location="$location2"
      if [ -z "$location2" ]; then
       deb_lvl "No second delete location set"
      else
       delete_function
      fi
    else
      deb_lvl "Test codition not met, found files in $download_flac or $rip_flac but none in $location2, possible failed conversion"
      rm -r /tmp/"$lockname"
    fi
  else
    err_lvl "Expected files in $download_flac or $rip_flac and no rsync errors, one of these conditions failed"
    exit 66
  fi
}
#
check_source () {
  find "$download_flac" -mindepth 1 -print -quit 2>/dev/null | grep -q . #<---Command above returns 0 for contents found, or 1 if nothing found
  if [[ "$?" = "0" ]]; then
    ntf_lvl "Located files in directory $download_flac"
    test_flac_down="y"
  else
    ntf_lvl "no files located in directory $download_flac"
    test_flac_down="n"
  fi
  find "$rip_flac" -mindepth 1 -print -quit 2>/dev/null | grep -q . #<---Command above returns 0 for contents found, or 1 if nothing found
  if [[ "$?" = "0" ]]; then
    ntf_lvl "Located files in directory $rip_flac"
    test_flac_rip="y"
  else
    ntf_lvl "no files located in directory $rip_flac"
    test_flac_rip="n"
  fi
}
#
#
#+-------------------+
#+---Initial Setup---+
#+-------------------+
#
#Grab PID
script_pid=$(echo $$)
deb_lvl "MusicSync scripts PID is: $script_pid"
#display version
deb_lvl "Version is: $version"
#Check for existance FFMPEG
if ! command -v ffmpeg &> /dev/null
then
  err_lvl "FFMPEG could not be found, script won't function wihout it"
  exit 67
else
  ntf_lvl "FFMPEG command located, continuing"
fi
#
# check for config file existance
if [[ ! -f "$config_file" ]]; then
  err_lvl "config file $config_file does not appear to exist"
  deb_lvl "attempting to source config file from default location"
  config_file="$HOME/.config/ScriptSettings/sync_config.sh"
  if [[ ! -f "$config_file" ]]; then
    err_lvl "config file still not located at $config_file, script exiting"
    rm -r /tmp/"$lockname"
    exit 65
  else
    deb_lvl "located default config file at $config_file, continuing"
    source "$config_file"
  fi
else
  # source config file
  ntf_lvl "Config file found, using $config_file"
  source "$config_file"
fi
#
# check if beets is intalled
if [[ ! -f "$beets_path" ]]; then
  err_lvl "a beets install at $beets_path not detected, please install and re-run"
  rm -r /tmp/"$lockname"
  exit 67
else
  ntf_lvl "Beets install detected, using $beets_path"
fi
#
#
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
  ntf_lvl "no input files detected, exiting"
  rm -r /tmp/"$lockname"
  exit 0
fi
#+---------------------------+
#+---Start Conversion Work---+
#+---------------------------+
# ALAC - convert flacs to alac and copy to the ALAC library imports first by using -c flag to specify an alternative config to merge"
config_yaml="alac_config.yaml"
ntf_lvl "config.yaml set as $config_yaml"
beets_config_path=$(echo "$beets_alac_path")
ntf_lvl "beets_config_path set as $beets_config_path"
section=${config_yaml::-12}
ntf_lvl "section running is $section"
if [[ "$music_alac" -eq 1 ]]
then
  beets_function
  sleep 1s
  deb_lvl "should sync is set to: $should_sync"
  if [[ "$should_sync" == "y" ]]
  then
    ntf_lvl "$section sync started"
    rsync "$rsync_remove_source" "$rsync_prune_empty" "$rsync_alt_vzr" "$alaclibrary_source" "$M4A_musicdest"
    rsync_error_catch
    ntf_lvl "$section sync finished"
  else
    ntf_lvl "no $section conversions, so no sync"
  fi
else
  ntf_lvl "$section conversion not selected" #<---I think this is the issue with the spurious logging name error
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
  ntf_lvl "$section not selected"
fi
#
# FLAC - correct the flac file tags now and move to the FLAC import library using -c flac to specify an alternative config to merge
config_yaml="flac_config.yaml"
ntf_lvl "config.yaml set as $config_yaml"
beets_config_path=$(echo "$beets_flac_path")
ntf_lvl "beets_config_path set as $beets_config_path"
section=${config_yaml::-12}
ntf_lvl "section running is $section"
if [[ "$music_flac" -eq 1 ]]
then
  beets_function
  sleep 1s
  if [[ "$should_sync" == "y" ]]
  then
    ntf_lvl "$section sync started"
    rsync "$rsync_remove_source" "$rsync_prune_empty" "$rsync_alt_vzr" "$flaclibrary_source" "$FLAC_musicdest"
    rsync_error_catch
    ntf_lvl "$section sync finished"
  else
    ntf_lvl "no $section conversions, so no sync"
  fi
else
  ntf_lvl "$section conversion not selected"
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
#+-----------------------+
#+---MUSIC SERVER sync---+
#+-----------------------+
if [[ "$musicserver_sync" -eq 1 ]]
then
  echo "-------------------------------------------------------------------------------------"
  ntf_lvl "MUSIC SERVER sync SELECTED, sync started"
  rsync "$rsync_alt_vzr" "$musicserver_source" "$musicserver_user"@"$musicserver_ip":"$musicserver_dest"
  rsync_error_catch
  ntf_lvl "MUSIC SERVER sync finished"
  update_musiclibrary
  sleep 30s
  clean_musiclibrary
else
  echo "-------------------------------------------------------------------------------------"
  ntf_lvl "MUSIC SERVER sync DESELECTED, no sync"
fi
#
#
# all done
rm -r /tmp/"$lockname"
ntf_lvl "MusicSync.sh completed successfully"
exit 0
