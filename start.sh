#!/bin/sh
#
# Script to backup database
#

# Where required binaries?
MONGOD_BIN="sudo ~/mongodb/bin/mongod"
SCREEN_BIN="/usr/bin/screen"

# Start new instances and bind them to screen so we can get to a console session

echo "Starting Mongo..."
$SCREEN_BIN -S MONGO -d -m $MONGOD_BIN
echo "Mongo started on MONGO screen"

echo "Starting server"
$SCREEN_BIN -S SERVER -ad  script/server -p 3033
echo "Server started on SERVER screen"

echo "Starting Judge"
$SCREEN_BIN -S JUDGE -ad ruby app/actors/judge.rb
echo "Judge started on JUDGE screen"

$SCREEN_BIN -ls

echo "screen -ls" lists attached screens
echo "screen -r MONGO" re-attach to screen session at [MONGO]
echo "When in screen 'ctrl+a+d' to detach"
