#!/bin/bash

killall chromium
killall node

coffee /home/pi/Projects/MagicMirror/app.coffee 2>&1 > /dev/null &
sleep 15 && chromium --kiosk "http://localhost:8080" 2>&1 > /dev/null &