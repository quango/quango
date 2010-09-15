#!/bin/sh
#
# Script to backup database
#

echo "Backup started"
/home/sp/mongodb/bin/mongodump -d pegasus-development -o backup
echo "Backup completed"
