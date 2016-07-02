#!/bin/bash

killall chromium
killall node

coffee /home/pi/Projects/MagicMirror/app.coffee &
sleep 15 && chromium --kiosk "http://localhost:8080" &