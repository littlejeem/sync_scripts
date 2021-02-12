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
version="1.0"
#
#
#+---------------------+
#+---"Set Variables"---+
#+---------------------+
scriptlong="MusicSyncMultiDisc.sh" # imports the name of this script
lockname=${scriptlong::-3} # reduces the name to remove .sh
script_pid=$(echo $$)
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
source $HOME/bin/standalone_scripts/helper_script.sh
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
  log_err "Failed to find: $JAIL_FATAL, JAIL_FATAL is unset or set to the empty string, script cannot continue. Exiting!"
  rm -r /tmp/"$lockname"
  exit 64
 else
  log "variable found, using: $JAIL_FATAL"
 fi
}
#
debug_missing_var () {
 if [ -z "${JAIL_DEBUG}" ]; then
  log_deb "JAIL_DEBUG $JAIL_DEBUG is unset or set to the empty string, may cause issues"
 else
  log "variable found, using: $JAIL_DEBUG"
 fi
}
#
beets_function () {
 log "$section processing started"
 if find "$download_flac" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
  log "files located in $download_flac"
  OUTPUT=$("$beets_path" "$beets_switch" "$beets_config_path"/"$config_yaml" import -q "$download_flac")
  timestamp=$(date +%a%R)
  echo $OUTPUT | grep "Skipping"
  if [[ $? = 0 ]]; then
    log_deb "detected beets skipping"
    unknown_artist="$rip_flac""Unknown Artist"
    log_deb "$unknown_artist"
    log_deb "Generic 'Unknown Artist' folder, assuming non tagging by beets, keeping folder appended with timestamp"
    mv "$unknown_artist" "$unknown_artist""-$timestamp"
  fi
  rm "$beets_config_path"/musiclibrary.blb
  should_sync="y"
 else
  log_deb "$download_flac is empty, no conversion needed"
 fi
 if find "$rip_flac" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
  log "files located in $rip_flac"
  OUTPUT=$("$beets_path" "$beets_switch" "$beets_config_path"/"$config_yaml" import -q "$rip_flac")
  timestamp=$(date +%a%R)
  echo $OUTPUT | grep "Skipping"
  if [[ $? = 0 ]]; then
    log_deb "detected beets skipping"
    unknown_artist="$rip_flac""Unknown Artist"
    log_deb "$unknown_artist"
    log_deb "Generic 'Unknown Artist' folder, assuming non tagging by beets, keeping folder appended with timestamp"
    mv "$unknown_artist" "$unknown_artist""-$timestamp"
  fi
  rm "$beets_config_path"/musiclibrary.blb
  should_sync="y"
 else
  log_deb "$rip_flac is empty, no conversion needed"
 fi
 log "$section processing finished"
}
#
#
rsync_error_catch () {
  if [ $? == "0" ]
   then
    log "rsync completed successfully"
   else
    log_err "rsync produced an error"
    rsync_error_flag="y"
  fi
}
#
delete_function () {
  includeonly="/home/jlivin25/Music/Rips/Unknown Artist"
  sleep $sleep_time
  find "$location" -mindepth 1 -maxdepth 1 -type d -not -wholename ""$location"Unknown\ Artist-*" -prune -exec echo '{}' \;
  sleep $sleep_time
  find "$location" -mindepth 1 -maxdepth 1 -type d -not -wholename ""$location"Unknown\ Artist-*" -prune -exec rm -rf '{}' \;
}
#
Logic1 () {
  if [ "$test_flac_down" = "y" ] || [ "$test_flac_rip" = "y" ] && [ -z "$rsync_error_flag" ]; then
    find "$location2" -mindepth 1 -print -quit 2>/dev/null | grep -q . #<---Command above returns 0 for contents found, or 1 if nothing found
    if [[ "$?" = "0" ]]; then
      log "Test conditions met, I am deleting..."
      location="$download_flac"
      delete_function
      location="$rip_flac"
      delete_function
      location="$location2"
      if [ -z "$location2" ]; then
       log_deb "No second delete location set"
      else
       delete_function
      fi
    else
      log_deb "Test codition not met, found files in $download_flac or $rip_flac but none in $location2, possible failed conversion"
      rm -r /tmp/"$lockname"
    fi
  else
    log_err "Expected files in $download_flac or $rip_flac and no rsync errors, one of these conditions failed"
    exit 66
  fi
}
#
check_source () {
  find "$download_flac" -mindepth 1 -print -quit 2>/dev/null | grep -q . #<---Command above returns 0 for contents found, or 1 if nothing found
  if [[ "$?" = "0" ]]; then
    log "Located files in directory $download_flac"
    test_flac_down="y"
  else
    log "no files located in directory $download_flac"
    test_flac_down="n"
  fi
  find "$rip_flac" -mindepth 1 -print -quit 2>/dev/null | grep -q . #<---Command above returns 0 for contents found, or 1 if nothing found
  if [[ "$?" = "0" ]]; then
    log "Located files in directory $rip_flac"
    test_flac_rip="y"
  else
    log "no files located in directory $rip_flac"
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
log_deb "MusicSync scripts PID is: $script_pid"
#display version
log_deb "Version is: $version"
#Check for existance FFMPEG
if ! command -v ffmpeg &> /dev/null
then
  log_err "FFMPEG could not be found, script won't function wihout it"
  exit 67
else
  log "FFMPEG command located, continuing"
fi
#
# check for config file existance
if [[ ! -f "$config_file" ]]; then
  log_err "config file $config_file does not appear to exist"
  log_deb "attempting to source config file from default location"
  config_file="$HOME/.config/ScriptSettings/sync_config.sh"
  if [[ ! -f "$config_file" ]]; then
    log_err "config file still not located at $config_file, script exiting"
    rm -r /tmp/"$lockname"
    exit 65
  else
    log_deb "located default config file at $config_file, continuing"
    source "$config_file"
  fi
else
  # source config file
  log "Config file found, using $config_file"
  source "$config_file"
fi
#
# check if beets is intalled
if [[ ! -f "$beets_path" ]]; then
  log_err "a beets install at $beets_path not detected, please install and re-run"
  rm -r /tmp/"$lockname"
  exit 67
else
  log "Beets install detected, using $beets_path"
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
#if [[ $flagA = "1" ]]; then
  echo "Enter Folder Names in CD order; spaces seperate values, escape spaces as normal:"
  read -a names
  #
  echo "${names[0]}, ${names[1]}, ${names[2]} ${names[3]}"
  #
  cd1=${names[0]}
  cd2=${names[1]}
  cd3=${names[2]}
  cd4=${names[3]}
  #
  if [[ -z $cd3 && -z $cd4 ]]; then
    echo "CD1 is $cd1, CD2 is $cd2"
    mkdir "$rip_flac"/Unknown\ Artist1
    mv "$rip_flac"/"$cd1"/Unknown\ Album Unknown\ Artist1/Unknown\ Album\ cd1
    mv "$rip_flac"/"$cd2"/Unknown\ Album Unknown\ Artist1/Unknown\ Album\ cd2
    rm -r "$rip_flac"/"$cd1" "$rip_flac"/"$cd2"
  elif [[ -z $cd4 ]]; then
    echo "CD1 is $cd1, CD2 is $cd2, CD3 is $cd3"
    mkdir "$rip_flac"/Unknown\ Artist1
    mv "$rip_flac"/"$cd1"/Unknown\ Album Unknown\ Artist1/Unknown\ Album\ cd1
    mv "$rip_flac"/"$cd2"/Unknown\ Album Unknown\ Artist1/Unknown\ Album\ cd2
    mv "$rip_flac"/"$cd3"/Unknown\ Album Unknown\ Artist1/Unknown\ Album\ cd3
    rm -r "$rip_flac"/"$cd1" "$rip_flac"/"$cd2" "$rip_flac"/"$cd3"
  else
    echo "CD1 is $cd1, CD2 is $cd2, CD3 is $cd3, CD4 is $cd4"
    mkdir "$rip_flac"/Unknown\ Artist1
    mv "$rip_flac"/"$cd1"/Unknown\ Album Unknown\ Artist1/Unknown\ Album\ cd1
    mv "$rip_flac"/"$cd2"/Unknown\ Album Unknown\ Artist1/Unknown\ Album\ cd2
    mv "$rip_flac"/"$cd3"/Unknown\ Album Unknown\ Artist1/Unknown\ Album\ cd3
    mv "$rip_flac"/"$cd4"/Unknown\ Album Unknown\ Artist1/Unknown\ Album\ cd4
    rm -r "$rip_flac"/"$cd1" "$rip_flac"/"$cd2" "$rip_flac"/"$cd3" "$rip_flac"/"$cd4"
  fi
#fi
#
#
#+---------------------------+
#+---Start Conversion Work---+
#+---------------------------+
# ALAC - convert flacs to alac and copy to the ALAC library imports first by using -c flag to specify an alternative config to merge"
config_yaml="alac_config.yaml"
log "config.yaml set as $config_yaml"
beets_config_path=$(echo $beets_alac_path)
log "beets_config_path set as $beets_config_path"
section=${config_yaml::-12}
log "section running is $section"
if [[ "$music_alac" -eq 1 ]]
then
  beets_function
  sleep 1s
  log_deb "should sync is set to: $should_sync"
  if [[ "$should_sync" == "y" ]]
  then
    log "$section sync started"
    rsync "$rsync_remove_source" "$rsync_prune_empty" "$rsync_alt_vzr" "$alaclibrary_source" "$M4A_musicdest"
    rsync_error_catch
    log "$section sync finished"
  else
    log "no $section conversions, so no sync"
  fi
else
  log "$section conversion not selected"
fi




# FLAC - correct the flac file tags now and move to the FLAC import library using -c flac to specify an alternative config to merge
config_yaml="flac_config.yaml"
log "config.yaml set as $config_yaml"
beets_config_path=$(echo $beets_flac_path)
log "beets_config_path set as $beets_config_path"
section=${config_yaml::-12}
log "section running is $section"
if [[ "$music_flac" -eq 1 ]]
then
  beets_function
  sleep 1s
  if [[ "$should_sync" == "y" ]]
  then
    log "$section sync started"
    rsync "$rsync_remove_source" "$rsync_prune_empty" "$rsync_alt_vzr" "$flaclibrary_source" "$FLAC_musicdest"
    rsync_error_catch
    log "$section sync finished"
  else
    log "no $section conversions, so no sync"
  fi
else
  log "$section conversion not selected"
fi












rm -r /tmp/$lockname
