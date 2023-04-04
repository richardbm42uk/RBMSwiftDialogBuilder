#!/bin/bash

# RBM Installed Items EA

prefFile="/Library/Managed Preferences/com.rbm.swiftdialogbuild.plist"

### Get a specific key from preferences
readPref(){
	/usr/libexec/PlistBuddy -c "Print $1" "$prefFile" 2>/dev/null
}

if [ -e "$prefFile" ]; then
	
	index=0
	while [ -n "$itemTitle" ] || (( $index < 1 )); do
		itemTitle="$(readPref "installList:$index:label")"
		if [ -n "$itemTitle" ]; then
			if [ -n "$itemList" ]; then
				itemList="$itemList
$itemTitle"
			else
				itemList="$itemTitle"
			fi
		fi
		index=$(( $index + 1))
	done
	
	echo "<result>$itemList</result>"
	
else
	
	echo "<result></result>"
	
fi