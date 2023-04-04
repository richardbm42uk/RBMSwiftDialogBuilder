#!/bin/bash

# RBM Build Status EA

prefFile="/Library/Preferences/com.rbm.swiftdialogbuild.plist"

### Get a specific key from preferences
readPref(){
	/usr/libexec/PlistBuddy -c "Print $1" "$prefFile" 2>/dev/null
}

if [ -e "$prefFile" ]; then
	
	result=$(readPref "buildStatus")
	echo "<result>$result</result>"
	
else
	
	echo "<result></result>"
	
fi