#!/bin/sh
#
# Script to backup database
#

echo "Restore started"
sudo ~/mongodb/bin/mongorestore -d pegasus-development  backup/pegasus-development --drop
sudo ~/mongodb/bin/mongorestore -d pegasus-development  backup/pegasus-development
echo "Restore completed"
