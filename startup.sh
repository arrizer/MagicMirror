#!/bin/bash

killall chromium
killall node

cd /home/pi/Projects/MagicMirror/
pm2 stop app.coffee
pm2 start app.coffee
sleep 15 && chromium --disable-session-crashed-bubble --disable-infobars --kiosk "http://localhost:8080" 2>&1 > /dev/null &