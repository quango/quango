#!/bin/sh
#
# Script to backup database
#

echo "Backup started"
~/mongodb/bin/mongodump -d daily-development -o backup
echo "Backup completed"
