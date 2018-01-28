#!/bin/bash

killall chromium-browser
cd /home/pi/MagicMirror/
sudo pm2 kill
sudo pm2 start app.coffee
sleep 5
sh /home/pi/scripts/start_chromium_browser