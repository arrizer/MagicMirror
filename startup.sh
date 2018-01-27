#!/bin/bash

killall chromium-browser
cd /home/pi/MagicMirror/
pm2 stop app.coffee
pm2 start app.coffee
killall chromium-browser
sh /home/pi/scripts/start_chromium_browser