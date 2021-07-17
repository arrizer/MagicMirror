#!/bin/bash

scp config.json pi@magicmirror.local:~/MagicMirror/config.json
ssh pi@magicmirror.local "cd ~/MagicMirror; git pull; ./startup.sh"