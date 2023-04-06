# RBM SwiftDialog Builder

Yet another script to configure Mac build processes using Jamf Pro and a graphical front-end with SwiftDialog.

## Why Bother?

If you’re the sort of person who’ll be reading this document, you’ll already be thinking
Why do we need another graphical front end for macOS builds? We have DEP Notify and its relatives NoMAD Notify and Jamf Connect Notify? 
There are pretty good off-the-shelf scripts for getting those tools to run a bunch of Jamf policies in a certain order and give a nice interface for that. Why bother changing?

#### First up…
DEP Notify hasn’t been graphically updated since macOS 10.10 Yosemite which still appears in its default banner graphic. That was released in 2014 and today in 2023, even hardware released in 2016 has made it to the scrap pile. In the interim, Apple have completely refreshed the appearance of macOS, implemented a whole new API for graphics (SwiftUI) and switched to a different CPU architecture. In that light, DEPNotify feels a bit old and rubbish.

#### Moreover…
When DEP Notify launched, the policy was king in the world of deployment. But Jamf policies have started to lose their place as premier method of app installation. While deploying from the Mac App Store using VPP has limitations, many Jamf admins got their start in primarily iOS focused environments and prefer the more automatic approach to App deployment and licensing afforded by that method - Microsoft Office being available via VPP also makes it an attractive approach. However, the real shake-up has come with Jamf’s own App Catalog, introduced in March 2022 as part of Jamf Pro 10.37. 
While the Jamf App Catalog has some major drawbacks and limitations, it has clear benefits for simplifying workflows and patch management and we are assured it is the future. So while the future of policies looks to move from packages to Installomator, workflows that are designed to work with all install methods and not just policies are going to become more important. That is what this script attempts to solve.

#### Finally…
There’s a bit of a learning curve with build scripts. The curve goes from creating packages in a drag-and-drop interface or setting up a few smart groups to suddenly needing to understand long and complex bash scripts and set a whole bunch of settings. Even worse, if you have a few different “builds” to deploy - like the IT department, the Art department, that one lad in finance who insists he needs a Mac even though the rest of that department are Windows only - a plethora of clone scripts are required each with their own tweaks.

This might be somewhat inevitable, but the complexity can put some workflows out of reach of some administrators. There’s always room to make things easier to work with.
## Features and Benefits

##### Asynchronous Installation Tracking
Items are marked as complete as they install as soon as the script detects a specific file has appeared on the client machine (eg: /Applications/Keynote.app). It doesn’t matter what order or method was used to install them
##### Jamf Policy Triggering

Custom Policy Triggers can be run sequentially from the script. As intended, each policy will install a separate item in a specific order - much like DEPNotify workflows.
##### Modern Configurable Interface
 The script makes it simple to customise the look of the banner and icon displayed as well. It looks modern and adding app icons is simple.
##### Configuration Profile
 The script can either be configured by changing the variables and arrays directly or by using a preference file - typically with a configuration profile. This makes it simple to deploy the same script to multiple Macs in an estate while installing different content simply by deploying a different profile.
##### Works with DEP and UIE workflows
 Because the script runs GUI commands asynchronously to Jamf Policy commands, it is highly suitable for DEP based workflows. The lightweight supporting items (approximately 6MB) can be installed at enrolment allowing the enrolment policy to start before users reach the login window. Upon logging in, they are presented with the current status of their build progress. If any installations have already occurred, they will be able to see the state of the installation - rather than some workflows that wait for the DEPNotify window to launch before running any installations by policy.
##### Custom Schema To allow easy setup of Configuration Profiles, a JSON Custom schema is available
##### Easy to Deploy 1. Deploying multiple builds follows these steps 
1. Setting up scoping for VPP and Jamf Catalog apps
1. Creating policies with custom triggers for each item to be installed by policy.
1. Creating and scoping a configuration profile with a list of what to display and policies to call for each build
1. Optionally packaging graphical resources for logos and banners
1. Creating a single enrolment policy to deploy the script
