#!/bin/bash

ssh pi@magicmirror.local "cd /home/pi/MagicMirror; git pull; scp matthias@saturn.local:/Users/matthias/Documents/Projects/MagicMirror/config.json .; ./startup.sh"