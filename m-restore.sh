#!/bin/sh
#
# Script to backup database
#

echo "Restore started"
sudo ~/mongodb/bin/mongorestore -d daily-development  backup/daily-development --drop
sudo ~/mongodb/bin/mongorestore -d daily-development  backup/daily-development
echo "Restore completed"
