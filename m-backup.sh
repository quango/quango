#!/bin/sh
#
# Script to backup database
#

echo "Backup started"
/home/sp/mongodb/bin/mongodump -d daily-development -o backup
echo "Backup completed"
