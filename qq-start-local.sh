#!/bin/sh
#
# Script to backup database
#

# Where required binaries?
#MONGOD_BIN="sudo ~/mongodb/bin/mongod"
SCREEN_BIN="/usr/bin/screen"

echo "Starting servers"
$SCREEN_BIN -S q1 -d -m script/server -p 3033
$SCREEN_BIN -S q2 -d -m script/server -p 3034
#$SCREEN_BIN -S q3 -d -m script/server -p 3035

echo "Starting Judge"
JUDGE_PATH=""

$SCREEN_BIN -S JUDGE -d -m ruby app/actors/judge.rb
#echo "Judge started on JUDGE screen"

$SCREEN_BIN -ls

echo "screen -ls" lists attached screens
echo "screen -r JUDGE" re-attach to screen session at [JUDGE]
echo "When in screen 'ctrl+a+d' to detach"
echo "screen -wipe" kills dead screens
