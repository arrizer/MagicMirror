#!/bin/bash

killall chromium-browser
cd /home/pi/MagicMirror/
pm2 kill
pm2 start app.coffee
sleep 5
sh /home/pi/scripts/start_chromium_browser