#!/bin/bash

###### Swift Dialog Build Dialog
###### By Richard Brown-Martin 2023

#### Static Variables
# All Static Variables can be overridden by the Configuration Profile
prefFile="/Library/Managed Preferences/com.rbm.swiftdialogbuild.plist"

## Basic Dialog Settings
# Title for top of dialog
title="Setting Up..."
# Main message for dialog
message="Getting your computer ready to use and installing apps..."
# Icon for the for the Dialog - replaced with a computer if left blank
dialogIcon="/Users/Shared/images/academia-login-logo.png"

## Dialog Appearance
# Blur the background of the screen. Pass anything other than false or no to activate.
fullScreen=""
# Banner Image - Path or URL for an image to use in the banner
bannerImage="/Users/Shared/images/rbm-strip.jpg"
#bannerImage=""
# Colour for Title Text - either a colour name or HEX
titleColour=""
# Title Text superimposed over banner image. Pass anything other than false or no to activate.
titleOnBanner="false"

### Build Information
# Optional Path for a "build flag" preference file to write at the end of installation
buildFlagPath=""
# Optional Build Name to write as part of "build flag"
buildName=""

### Cleanup Tasks
# Run any outstanding checkin policies during cleanup. Pass anything to activate or leave blank to skip.
cleanUpPolicy=""
# Run final inventory update during cleanup. Pass anything to activate or leave blank to skip.
cleanUpRecon=""

### Additional configuration
# Time Out (in seconds) to abort the main loop
timeout=1800
# Waiting time before dialog automatically closes (in seconds)
waitToClose=1800
# Exit behaviour - Reboot, Logout or Exit (default exit)
exitBehaviour=""

# Generic Icon path
genericIcon="/System/Library/PrivateFrameworks/MobileIcons.framework/Versions/A/Resources/DefaultIcon-60@2x~iphone.png"

# Log Path
logPath=/var/log/build.log

### List of install items in format...
# "Label, Path for completed item, Policy Trigger (If necessary), Icon path or URL"

# Testing Install Array 1
#installList=(
# "Google Chrome,/Applications/Google Chrome.app,,"
# "Keynote,/Applications/Keynote.app,,https://ics.services.jamfcloud.com/icon/hash_f0048723c3075d745f4104f7f95ccb059689f4523ad4411aab3f2754061929f3"  
# "Microsoft Excel,/Applications/Microsoft Excel.app,installexcel,https://ics.services.jamfcloud.com/icon/hash_721a7bf38cec7552ecd6ffaee9a0ed2ab21b2318639c23082250be12517fca1c"
# "Microsoft OneDrive,/Applications/OneDrive.app,,"
# "Microsoft Outlook,/Applications/Microsoft Outlook.app,installOutlook,https://ics.services.jamfcloud.com/icon/hash_b96ae8bdcb09597bff8b2e82ec3b64d0a2d17f33414dbd7d9a48e5186de7fd93"
# "Microsoft PowerPoint,/Applications/Microsoft Powerpoint.app,installPowerpoint,"
# "Microsoft Teams,/Applications/Microsoft Teams.app,,https://ics.services.jamfcloud.com/icon/hash_623505d45ca9c2a1bd26f733306e30cd3fcc1cc0fd59ffc89ee0bfcbfbd0b37e"
# "Microsoft Word,/Applications/Microsoft Word.app,,https://ics.services.jamfcloud.com/icon/hash_a4686ab0e2efa2b3c30c42289e3958e5925b60b227ecd688f986d199443cc7a7"
# "Pages,/Applications/Pages.app,,https://ics.services.jamfcloud.com/icon/hash_897f79c537a547a999cad36652d81cb34a23ff4fa8f028d061e40e26f6ad38a7"
# "Numbers,/Applications/Numbers.app,,https://ics.services.jamfcloud.com/icon/hash_97266d57fd2811e4dd3a0668bcd2c5c80bcbfbb29362dd5781015d2190844f38"
# "zoom.us,/Applications/zoom.us.app,,https://ics.services.jamfcloud.com/icon/hash_ad4aa8f819b365a848b798b32f3d42438cbfef2d5c62dd02283132673ec23871"
#)

# Testing Install Array 2
installList=(
  "Google Chrome,/Applications/Google Chrome.app,,"
  "Keynote,/Applications/Keynote.app,,https://ics.services.jamfcloud.com/icon/hash_f0048723c3075d745f4104f7f95ccb059689f4523ad4411aab3f2754061929f3"  
  "Pages,/Applications/Pages.app,,https://ics.services.jamfcloud.com/icon/hash_897f79c537a547a999cad36652d81cb34a23ff4fa8f028d061e40e26f6ad38a7"
  "Numbers,/Applications/Numbers.app,,https://ics.services.jamfcloud.com/icon/hash_97266d57fd2811e4dd3a0668bcd2c5c80bcbfbb29362dd5781015d2190844f38"
  "zoom.us,/Applications/zoom.us.app,,https://ics.services.jamfcloud.com/icon/hash_ad4aa8f819b365a848b798b32f3d42438cbfef2d5c62dd02283132673ec23871"
)


## Static variables that are unlikely to need to be changed

# Location of dialog, dialog command file and Jamf binary
dialogApp="/usr/local/bin/dialog"
dialogCMDFile="/var/tmp/dialog.log"
jamfBinary="/usr/local/bin/jamf"

#### Functions

### Dialog Commands
dialog_command(){
  echo "$(date): $1"
  echo "$1"  >> $dialogCMDFile
}

logIt(){
  echo "$(date): $1"
  echo "$(date): $1" >> $logPath
}

###
startUp(){
  # Record Start Time for Timeouts
  startTime=$(date +%s)
  # Stop the screen from sleeping while building
  caffeinate -dimsu &
  caffeinatePID=$!
  # Stop Jamf from doing anything unexpected during setup
  launchctl unload /Library/LaunchDaemons/com.jamfsoftware.task.1.plist
  # Perform Initial Recon
  $jamfBinary recon &
  reconPID=$!
}

### Get a specific key from preferences
readPref(){
  /usr/libexec/PlistBuddy -c "Print $1" "$prefFile" 2>/dev/null
}

### Load in all Preferences
getPrefs(){
  if [  -z "$exitBehaviour" ]; then
    exitBehaviour="Quit"
  fi
  # If Pref File is there, then replace everything in the script with a pref.
  if [ -e "$prefFile" ] && [ -n "$prefFile" ] ; then
    prefIndex=0
    unset installList
    while [ -n "$prefItemTitle" ] || (( $prefIndex < 1 )); do
      prefItemTitle="$(readPref "installList:$prefIndex:label" | xargs)"
      prefItemIcon="$(readPref "installList:$prefIndex:iconPath" | xargs)"
      prefItemPath="$(readPref "installList:$prefIndex:path" | xargs)"
      prefItemPolicy="$(readPref "installList:$prefIndex:jamfPolicy" | xargs)"
      if [ -n "$prefItemTitle" ]; then
        installList+=("$prefItemTitle,$prefItemPath,$prefItemPolicy,$prefItemIcon,")
      fi
      prefIndex=$(( $prefIndex + 1))
    done
    
    title="$(readPref "appearance:title" | xargs)"
    message=$(readPref "appearance:message" | xargs)
    dialogIcon="$(readPref "appearance:dialogIcon" | xargs)"
    
    fullScreen="$(readPref "appearance:fullscreen" | xargs)"
    bannerImage="$(readPref "appearance:titlebanner:bannerimage" | xargs)"
    titleColour="$(readPref "appearance:titlebanner:titlecolour" | xargs)"
    titleOnBanner="$(readPref "appearance:titlebanner:titleOnBanner" | xargs)"
    
    buildFlagPath="$(readPref "buidFlags:buildFlag:buildFlagPath" | xargs)"
    buildName="$(readPref "buidFlags:buildFlag:buildName" | xargs)"
    
    cleanUpPolicy="$(readPref "cleanup:cleanUpPolicy" | xargs)"
    cleanUpRecon="$(readPref "cleanup:cleanUpRecon" | xargs)"
    
    exitBehaviour="$(readPref "misc:exitAction" | xargs)"
    timeout=$(( $(readPref "misc:timeout") ))
    waitToClose=$(( $(readPref "misc:waitToClose") ))
    
  fi
  
  # Fix issues
  if (( $timeout < 60 )) || [ -z "$timeout" ]; then
    echo "Timeout should not be less than 1 minute, resetting to 5 minutes"
    timeout=300
  fi
  
  if (( $waitToClose < 1 )) || [ -z "$waitToClose" ]; then
    echo "Wait to close must be at least 1 second"
    waitToClose=1
  fi
  
  if [  -z "$title" ]; then 
    title=none
  fi
  
  if [ -z "$message" ]; then
    message="Starting setup..."
  fi
  
  if [ -z "$bannerImage" ]; then
    unset titleOnBanner
  fi
  
  # Count the items in the array
  arrayLength=${#installList[@]}
  completionLength=$(($arrayLength + 1))
  # Initialise counters
  completion=0
  jamfIndex=0
  dialogUpdates=( )
}

### Launch Dialog
launchDialog(){
  
  # Set an icon
  if [ -z "$dialogIcon" ]; then
    if system_profiler SPPowerDataType | grep -q "Battery Power" ; then
      dialogIcon="SF=laptopcomputer"
    else
      dialogIcon="SF=desktopcomputer"
    fi
  fi  
  
  # Calculate height of the dialog, maxing out at 90% of screen height
  pixHeight=$(( ( 90 * $arrayLength ) + 455 )) 
  
  # Dialog optional items
  if [ -z "$fullScreen" ] || [ "$fullScreen" = "false" ] || [ "$fullScreen" = "no" ]; then
    blurscreen=""
  else
    blurscreen="--blurscreen"
  fi
  
  if [  -n "$bannerImage" ]; then 
    banner="--bannerimage \"$bannerImage\""
    fullBannerHeight=$(sips -g pixelHeight "$bannerImage"| awk -F : '{print $2}')
    fullBannerWidth=$(sips -g pixelWidth "$bannerImage" | awk -F : '{print $2}')
    correctedBannerHeight=$(( $fullBannerHeight * 1640 / $fullBannerWidth ))
    if (( $correctedBannerHeight > 300 )); then
      correctedBannerHeight=300
    fi
    pixHeight=$(( $pixHeight + $correctedBannerHeight ))
  fi
  
  if [  -n "$titleColour" ]; then 
    titleFont="--titlefont colour=$titleColour"
  fi  
  
  if [ -z "$titleOnBanner" ] || [ "$titleOnBanner" = "false" ] || [ "$titleOnBanner" = "no" ]; then
    bannerTitle=""
  else
    if [ -n "$bannerImage" ]; then
      bannerTitle="--bannertitle"
      pixHeight=$(( $pixHeight - 100 ))
    else
      bannerTitle=""
    fi
  fi
  
  screenheights=$(system_profiler SPDisplaysDataType | grep Resolution | awk '{print $4}')
  for height in $screenheights; do
    if [ -z "$maxPixHeight" ] || (( $height < $maxPixHeight )); then
      maxPixHeight=$height
    fi
  done
  maxPixHeight=$(( $maxPixHeight * 9 / 10)) # Adjusted Max height is 90% of smallest display
  
  if (( $maxPixHeight < $pixHeight )); then
    pointHeight=$(( ( $maxPixHeight - 55 ) / 2 ))
    fontsize=$(( $maxPixHeight / $pixHeight * 14))
    if (( $fontsize < 10 )); then
      fontsize=10
    fi
  else
    pointHeight=$(( ( $pixHeight - 55 ) / 2 ))
    fontsize=14
  fi  
  
  # Configure the dialog
  dialogCMD="$dialogApp -p -o \
--title \"$title\" \
--message \"$message\" \
--messagefont \"size=$fontsize\" \
--icon \"$dialogIcon\" \
--overlayicon SF=arrow.down.circle.fill,palette=white,white,orange,bgcolor=none \
--progress $arrayLength \
--button1text \"Please Wait\" \
--button1disabled \
--height $pointHeight"
  
  # create the list of apps
  listitems=""
  for app in "${installList[@]}"; do
    listitems="$listitems --listitem '$(echo "$app" | cut -d ',' -f1)'"
  done
  
  
  # final command to execute
  dialogCMD="$dialogCMD $listitems $blurscreen $banner $bannerTitle $titleFont"
  
  # Launch dialog and run it in the background sleep for a second to let thing initialise
  eval "$dialogCMD" &
  dialogPID=$!
  running=2
  sleep 1
}

updateArrayItem(){
  updateArrayIndex=$1
  updateArrayNewState=$2
  # Breakdown the existing item
  updateArrayName="$(echo "${installList[$updateArrayIndex]}" | cut -d ',' -f1)"
  updateArrayPath="$(echo "${installList[$updateArrayIndex]}" | cut -d ',' -f2)"
  updateArrayPolicy="$(echo "${installList[$updateArrayIndex]}" | cut -d ',' -f3 | xargs )"
  updateArrayAppIcon="$(echo "${installList[$updateArrayIndex]}" | cut -d ',' -f4)"
  updateArrayOldState="$(echo "${installList[$updateArrayIndex]}" | cut -d ',' -f5)"
  if [  "$updateArrayOldState" != "$updateArrayNewState" ]; then
    # Update array with the new state
    installList[$updateArrayIndex]="$updateArrayName,$updateArrayPath,$updateArrayPolicy,$updateArrayAppIcon,$updateArrayNewState"
    # Add item to list that need their dialogs updated
    dialogUpdates+=($updateArrayIndex)
    # If something has completed or failed then add a tally to the completion counter
    if [ "$updateArrayNewState" = "complete" ] || [ "$updateArrayNewState" = "failed" ]; then
      completion=$(($completion + 1 ))
    fi
  fi
}

updateDialog(){
  updateDialogIndex=$1
  removeIndex=0
  removeLength=${#dialogUpdates[@]}
  newDialogUpdates=( )
  while (( $removeIndex < $removeLength )); do
    itemAtRemoveIndex="${dialogUpdates[$removeIndex]}"
    if [ "$updateDialogIndex" != "$itemAtRemoveIndex" ]; then
      newDialogUpdates+=($itemAtRemoveIndex)
    fi
    removeIndex=$(( $removeIndex + 1 ))
  done
  dialogUpdates=( "${newDialogUpdates[@]}" )
  # Get the relevant item info
  updateDialogName="$(echo "${installList[$updateDialogIndex]}" | cut -d ',' -f1)"
  updateDialogAppIcon="$(echo "${installList[$updateDialogIndex]}" | cut -d ',' -f4)"
  updateDialogState="$(echo "${installList[$updateDialogIndex]}" | cut -d ',' -f5)"
  # If no icon set, either use the generic item or if the install is complete, try the app icon
  if [ -z "$updateDialogAppIcon" ]; then
    if [ "$updateDialogState" = "complete" ]; then
      updateDialogArrayPath="$(echo "${installList[$updateDialogIndex]}" | cut -d ',' -f2)"
      if [[ "$updateDialogArrayPath" = *.app ]]; then
        updateDialogAppIcon="$updateDialogArrayPath"
      else
        echo "updateDialogName is using $genericIcon"
        updateDialogAppIcon="$genericIcon"
      fi
    else
      echo "updateDialogName is using $genericIcon"
      updateDialogAppIcon="$genericIcon"
    fi
  fi
  # From the status set the icon and message
  case $updateDialogState in
    complete) 
      updateDialogStatus="success"
      updateDialogText="Complete"
      dialog_command "progresstext: Install of \"$updateDialogName\" complete"
    ;;
    failed) 
      updateDialogStatus="fail"
      updateDialogText="Failed"
      dialog_command "progresstext: Install of \"$updateDialogName\" failed"
    ;;
    installing) 
      updateDialogStatus="wait"
      updateDialogText="Installing"
      dialog_command "progresstext: Install of \"$updateDialogName\" started"
    ;;
    pending) 
      updateDialogStatus="pending"
      updateDialogText="Queued"
    ;;
    waiting) 
      updateDialogStatus="wait"
      updateDialogText="Waiting"
    ;;
    *)
      echo "Something has gone wrong, $updateDialogState"
    ;;
  esac
  dialog_command "listitem: title: $updateDialogName, status: $updateDialogStatus, statustext: $updateDialogText, icon: $updateDialogAppIcon"
  dialog_command "progress: $completion"
}

# Once the dialog is up, populate the list with icons and statuses
populateList(){  
  dialog_command "progresstext: Waiting to Start..."
  populateIndex=0
  while (( $populateIndex < $arrayLength )); do
    populatePolicy="$(echo "${installList[$populateIndex]}" | cut -d ',' -f3 | xargs )"
    populateState="$(echo "${installList[$populateIndex]}" | cut -d ',' -f5)"
    # Only update state if not already set
    if [ -z "$populateState" ]; then
      # Determine if waiting or pending based on if item is a policy or not
      if [ -z "$populatePolicy" ]; then
        updateArrayItem $populateIndex "waiting"
      else
        updateArrayItem $populateIndex "pending"
      fi
    fi
    populateIndex=$(( $populateIndex + 1 ))
  done
}


## Jamf Checker - Checks if Jamf is running and starts it if necessary

jamfChecker(){
  # Check if all Jamf Policies have been run
  if (( $jamfIndex < $arrayLength )); then # Continue only if the Jamf Counter is less than the total items in the array
    # Check if Jamf is already running or not
    if [ -z "$jamfPID" ]; then # If no PID then start straight away
      jamfStarter
    else
      jamfRunningStatus=$(ps aux | grep -c " $jamfPID ")
      if (( $jamfRunningStatus < 2 )); then #If Jamf is no longer running then the previous policy should have finished
        # Check if the last policy worked
        jamfCheckerInstallCheckState=$(echo "${installList[$jamfIndex]}" | cut -d ',' -f5)
        if [ "$jamfCheckerInstallCheckState" != "complete" ] && [ "$jamfCheckerInstallCheckState" != "failed" ]; then
          # Check if the criteria is met, mark as complete once it is
          jamfCheckerInstallpolicyPath="$(echo "${installList[$jamfIndex]}" | cut -d ',' -f3 | xargs)"
          if [  -n "$jamfCheckerInstallpolicyPath" ]; then
            jamfCheckerInstallCheckPath="$(echo "${installList[$jamfIndex]}" | cut -d ',' -f2 | xargs)"
            jamfCheckWait=0
            until [  -e "$jamfCheckerInstallCheckPath" ] || (( $jamfCheckWait > 5 )); do
              sleep 1
              jamfCheckWait=$(($jamfCheckWait + 1))
            done
            if [  -e "$jamfCheckerInstallCheckPath" ]; then
              logIt "Policy trigger $jamfPolicy complete"
              updateArrayItem $jamfIndex "complete"
            else
              logIt "Policy trigger $jamfPolicy completed but files not found"
              updateArrayItem $jamfIndex "failed"
            fi
          fi  
        fi
        # Iterate the policy loop and unset the PID ready for the next policy, then get the next policy going.
        jamfIndex=$(( $jamfIndex + 1 ))
        unset jamfPID
        if (( $jamfIndex < $arrayLength )); then
          jamfStarter
        else 
          if (( $jamfIndex = $arrayLength )); then
            jamfIndex=$((jamfIndex + 1))
            logIt  "$(date): Jamf policies complete!"
            $jamfBinary recon &
          fi
        fi
      fi  
    fi
  fi
}


## Jamf Starter - Starts the next Jamf policy
jamfStarter(){
  # Find the next item that has a policy trigger
  if (( $jamfIndex < $completionLength )); then
    unset jamfPolicy
    while [ -z "$jamfPolicy" ] && (( $jamfIndex < $completionLength )); do
      jamfPolicy="$(echo "${installList[$jamfIndex]}" | cut -d ',' -f3 | xargs )"
      if [ -z "$jamfPolicy" ]; then
        jamfIndex=$((jamfIndex + 1))
      else
        logIt "Starting Jamf Policy trigger $jamfPolicy"
        updateArrayItem $jamfIndex "installing"
        $jamfBinary policy -event $jamfPolicy  -forceNoRecon &
        jamfPID=$!
        sleep 1
      fi
    done
  else
    logIt  "Jamf policies complete!"
    $jamfBinary recon &
  fi
}

# Wait for Dock before launching DEP Nofity. Important for DEP builds
waitToStart() {
    until [ -e "$dialogApp" ] && [ -n "$(pgrep -l "Dock")" ]; do
    if [ -n "$reconPID" ]; then
      reconRunningStatus=$(ps aux | grep -c " $reconPID ")
      if (( $reconRunningStatus < 2 )); then
        unset reconPID
      fi
      else
        jamfChecker
    fi
    sleep 3
  done
}

# Finalise Dialog if everything worked
finaliseGood(){
  dialog_command "overlayicon: SF=checkmark.circle.fill,palette=white,white,green,bgcolor=none"
  dialog_command "progresstext: Installation complete"
  dialog_command "progress: complete"
  dialog_command "button1text: $exitBehaviour"
  dialog_command "button1: enable" 
}

# Finalise Dialog if anything failed
finaliseBad(){
  finaliseIndex=0
  while (( $finaliseIndex < $arrayLength )); do
    finaliseCheckState="$(echo "${installList[$finaliseIndex]}" | cut -d ',' -f5)"
    if [ "$finaliseCheckState" != "complete" ] && [ "$finaliseCheckState" != "failed" ]; then
      updateArrayItem $finaliseIndex failed
    fi
    finaliseIndex=$(( $finaliseIndex + 1))
  done
  
  refreshDialog
  dialog_command "overlayicon: SF=x.circle.fill,palette=white,white,red,bgcolor=none"
  dialog_command "progresstext: Installation has completed but some items have failed"
  dialog_command "progress: complete"
  dialog_command "button1text: $exitBehaviour"
  dialog_command "button1: enable" 
  
  exitCode=1
}

# Install Checker
installChecker(){
  installCheckIndex=0
  while (( $installCheckIndex < $arrayLength )); do
    # Find the State and if it's a policy installed item
    installCheckState="$(echo "${installList[$installCheckIndex]}" | cut -d ',' -f5)"
    installCheckSkipJamf="$(echo "${installList[$installCheckIndex]}" | cut -d ',' -f3 | xargs)"
    # Skip checking items that are already installed or run from a Jamf policy
    if [ "$installCheckState" != "complete" ] && [ "$installCheckState" != "failed" ] && [ -z "$installCheckSkipJamf"  ]; then
      # Check if the criteria is met, mark as complete once it is
      installCheckPath="$(echo "${installList[$installCheckIndex]}" | cut -d ',' -f2)"
      if [  -e "$installCheckPath" ]; then
        installCheckName="$(echo "${installList[$installCheckIndex]}" | cut -d ',' -f1)"
        logIt "Item $installCheckName complete"
        updateArrayItem $installCheckIndex "complete"
      fi
    fi  
    installCheckIndex=$(( $installCheckIndex + 1 ))
  done 
}

# Check time running
checkTimeout(){
  timeNow=$(date +%s)
  timeRunning=$(( $timeNow - $startTime ))
}

# Refresh all items in the dialog
refreshDialog(){
  for indexToDraw in ${dialogUpdates[@]}; do
    updateDialog $indexToDraw
  done
}

writeBuildFlag(){
  # If Build Flag set, write build flag
  if [ -n "$buildFlagPath" ]; then
    defaults write "$buildFlagPath" buildStatus "Incomplete"
    # Write name of build if set
    if [ -n "$buildName" ]; then
      defaults write "$buildFlagPath" buildType "$buildName"
    fi
    # Write date of completeion
    buildStartDate=$(date -j -f '%s' "$startTime" '+%Y-%m-%d %H:%M:%S %z' )
    defaults write "$buildFlagPath" buildStartDate -date "$buildStartDate"
  fi
  
}

# Cleanup
cleanUp(){
  dialog_command "overlayicon: SF=arrow.triangle.2.circlepath.circle.fill,palette=white,white,blue,bgcolor=none"
  dialog_command "progresstext: Performing final actions"
  dialog_command "progress: "
  if [ -n "$cleanUpPolicy" ] && [ "$cleanUpPolicy" != "false" ] && [ "$cleanUpPolicy" != "no" ]; then
    dialog_command "progresstext: Performing final management actions..."
    $jamfBinary policy -forceNoRecon
  fi
  # If Build Flag set, update build flag
  if [ -n "$buildFlagPath" ]; then
    # Write Status depending on completion status
    if (( $completion < $arrayLength )); then
      defaults write "$buildFlagPath" buildStatus "Failed" 
    else
      defaults write "$buildFlagPath" buildStatus "Complete" 
    fi
    # Write date of completeion
    buildCompleteDate=$(date '+%Y-%m-%d %H:%M:%S %z')
    defaults write "$buildFlagPath" buildCompleteDate -date "$buildCompleteDate"
  fi
  if [ -n "$cleanUpRecon" ] && [ "$cleanUpRecon" != "false" ] && [ "$cleanUpRecon" != "no" ] ; then
    dialog_command "progresstext: Performing Inventory Update..."
    $jamfBinary recon
  fi
}

waitToEnd(){
  running=$(ps aux | grep -c " $dialogPID ")
  if (( $(($running)) > 1 )); then 
    timer=0
  while (( $(($running)) > 1 )) && (( $timer < $waitToClose )); do
    running=$(ps aux | grep -c " $dialogPID ")
    timer=$(( $timer + 1))
    sleep 1
  done
  fi
}

waitForRecon(){
  reconRunningStatus=$(ps aux | grep -c " $reconPID ")
  if (( $reconRunningStatus > 1 )); then
    checkTimeout 
    logIt "Waiting for Recon to Complete"
    until (( $reconRunningStatus < 2 )) || (( $timeRunning > $timeout )); do
      sleep 1
      checkTimeout 
      reconRunningStatus=$(ps aux | grep -c " $reconPID ")
    done
    unset reconPID
  fi
}

countdownWarning(){
  running=$(ps aux | grep -c " $dialogPID ")
  countdown=5
  while (( $(($running)) > 1 )) && (( $countdown > -1 )); do
    dialog_command "progresstext: $1 in $countdown..."
    sleep 1
    countdown=$(( $countdown - 1))
    running=$(ps aux | grep -c " $dialogPID ")
  done
}

endDialog(){
  case $exitBehaviour in
    "Restart" | "restart") 
      countdownWarning "Restarting"
      shutdown -r now
    ;;
    "Shut Down" | "shutdown") 
      countdownWarning "Shutting Down"
      shutdown -h now
    ;;
    "Log Out" | "logout") 
      countdownWarning "Logging Out"
      killall loginwindow
    ;;
    *) 
      countdownWarning "Closing Dialog"
      launchctl load "/Library/LaunchDaemons/com.jamfsoftware.task.1.plist"
      kill $caffeinatePID
      exit $exitCode
    ;;
  esac
}

getDialog(){
  # Get the URL of the latest PKG From the Dialog GitHub repo
  dialogURL=$(curl --silent --fail "https://api.github.com/repos/bartreardon/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")
  # Expected Team ID of the downloaded PKG
  expectedDialogTeamID="PWA5E9TQ59"
  
  # Check for Dialog and install if not found
  ##	if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then
  echo "Dialog not found. Installing..."
  # Create temporary working directory
  tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/dialog.XXXXXX" )
  # Download the installer package
  /usr/bin/curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"
  # Verify the download
  teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')
  
  echo $workDirectory
  echo $tempDirectory
  echo $dialogURL
  # Install the package if Team ID validates
  if [ "$expectedDialogTeamID" = "$teamID" ] || [ "$expectedDialogTeamID" = "" ]; then
    /usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
  else
    logIt "Dialog Team ID verification failed."
    exit 1
  fi
  # Remove the temporary working directory when done
  /bin/rm -Rf "$tempDirectory"  
  #	fi
}

#########################################
#### Start of Script ###################

## Startup
logIt "Starting Up"
startUp

# Get Prefs
logIt "Reading Preferences"
getPrefs 

# Write the inital flag values
writeBuildFlag

# If Swift Dialog doesn't exist, download it
getDialog

# Wait for the Dock to by running before launching any GUI
# Jamf policies will be started from here if required
logIt "Waiting for login"
waitToStart

# Launch the Dialog
logIt "Launching Dialog"
launchDialog 

# Launch the initial List
logIt "Configuring Dialog"
populateList
refreshDialog
checkTimeout

# Wait for recon to complete
waitForRecon

# Main build loop
logIt "Starting main loop"
while (( $completion < $arrayLength )) && (( $timeRunning < $timeout )); do
  ## Check if app is installed
  installChecker
  # Check if Jamf is running or has completed a trigger, then start new policies if needed
  jamfChecker 
  ## Refresh the interface
  refreshDialog
  checkTimeout
done

# One last check of everything
logIt "Performing final checks"
jamfChecker
installChecker
refreshDialog

# Cleanup tasks
logIt "Running Cleanup Tasks"
cleanUp

# Check if all items installed or if things timed out
if (( $completion < $arrayLength )); then
  logIt "Build failed, not all items completed"
  finaliseBad 
else
  logIt "Build complete!"
  finaliseGood 
fi

# Pause for a while so the person doing the build can see the results
logIt "Waiting to end"
waitToEnd

# Close out, Quit the script or reboot, shutdown or logout.
logIt "Dialog closing, goodbye..."
endDialog