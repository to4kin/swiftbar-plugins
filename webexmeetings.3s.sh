#!/bin/bash

# Get current status of a Webex Meetings with option to kill process.

# <xbar.title>Webex Meetings</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Anton Bastin</xbar.author>
# <xbar.author.github>to4kin</xbar.author.github>
# <xbar.desc>Get current status of a Webex Meetings with option to kill process.</xbar.desc>
# <xbar.image>https://i.imgur.com/v2aW5mo.png</xbar.image>

STATUS_COMMAND="ps -ax | grep -v grep | grep 'Webex Meetings'"
KILL_COMMAND="pkill -9 -f 'Webex Meetings'"

case "$1" in
    kill)
        # Kill Webex Meetings
        eval "$KILL_COMMAND"
        # Wait for kill so menu item refreshes instantly
        until eval "$STATUS_COMMAND"; do sleep 1; done
        osascript -e 'display notification "Webex Meetings successfully killed" with title "Webex Meetings" subtitle "Killed"'
        ;;
esac

if [ -n "$(eval "$STATUS_COMMAND")" ]; then
    echo "🎙"
    echo '---'
    echo 'Webex Meetings'
    echo 'Active'
    echo "Kill Webex Meetings | bash='$0' param1=kill terminal=false refresh=true"
else
    echo "🎧"
    echo '---'
    echo 'Webex Meetings'
    echo 'Inactive...'
fi