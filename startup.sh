#!/bin/bash

killall chromium-browser
cd /home/pi/MagicMirror/
pm2 kill
pm2 start deploy.json
sleep 5
env DISPLAY=:0 /usr/bin/chromium-browser --kiosk --disable-restore-session-state --remote-debugging-port=9222 http://localhost:8080