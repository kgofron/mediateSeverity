#!/bin/bash

grep -r :STATUSEXT /home/controls/bl11a/applications | grep record | cut -f2 -d" " | sed 's/\"//g' | sed 's/)//g' | sort -u
