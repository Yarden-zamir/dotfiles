#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle T3 Code
# @raycast.mode silent
# @raycast.packageName T3 Code
#
# Documentation:
# @raycast.description Show T3 Code, or hide it when it is in front
# @raycast.author Yarden
# @raycast.authorURL https://github.com/yarden-zamir

# Assign the hotkey (cmd+§) in Raycast. Ghostty owns plain § and F17.
# The nightly and stable builds may differ in bundle id; check with lsappinfo.
bundle=com.t3tools.t3code
# lsappinfo answers in ~20 ms; System Events took 0.3-1.3 s per call.
front=$(lsappinfo info -only bundleid "$(lsappinfo front)")
case $front in
*"\"$bundle\""*)
    # Hide through AppKit directly; System Events is the slow path.
    osascript -l JavaScript -e "ObjC.import('AppKit'); \$.NSRunningApplication.runningApplicationsWithBundleIdentifier('$bundle').firstObject.hide" >/dev/null
    ;;
*)
    /usr/bin/open -b "$bundle"
    ;;
esac
