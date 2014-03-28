#!/bin/bash

#Written by Andrew Huffman - andrew.j.huffman@gmail.com
#March 2014

#Purpose: To backup Dell KACE database and package files
#Setup:
#      fill in appropriate values for your environment
#      add to your crontab for scheduled backups
#requires the curl package be installed on your server

recipients="your comma separated email list"
bkup_path=/your/backup/path/
kace_host="your fqdn hostname"
password="your ftp password"
log=/your/log/path/backup_k1000_lastrun.log
backup_host="your backup server's hostname"
days_to_keep=3  #Remove anything older than this number of days


#Functions
DATE=`date +"%Y%m%d"`

function check_status () {
#checks status code passed and returns some output
  if [ $1 -eq 0 ]
  then
	echo "Successful"
  else
	echo "Failed"
  fi
}

function cleanup {
#Cleans up backups older than 3 days
find $bkup_path -mtime +$days_to_keep -delete
}


#Start work
echo "Starting K1000 Backup of DB DATA"
#K1000 DB
curl -u kbftp:$password ftp://$host/kbox_dbdata.gz -o "$bkup_path$DATE_kbox_dbdata.gz"
#collect result
dbstatus=$?
dbstate=`check_status $dbstatus`

echo "Starting K1000 Backup of FILE DATA"
#K1000 File Data (packages)
curl -u kbftp:$password ftp://$kace_host/kbox_file.tgz -o "$bkup_path$DATE_kbox_file.tgz"
#collect result
filestatus=$?
filestate=`check_status $filestatus`


#Set Overall Success or Failure based on the 2 results
if [ $filestatus -eq 0 ] && [ $dbstatus -eq 0 ]
then
    overall_state="SUCCESSFUL"
else
    overall_state="FAILURE"
fi

#Capture current contents of backup directory
contents=`ls -lh $bkup_path`


#Create Email Report
echo -e "$kace_host Backup to $backup_host on $DATE:\n\nBackups stored in: "$bkup_path"\n     DB Data:   $dbstate\n     File Data:  $filestate\n\n\nCheck log on $backup_host: "$log" for more details.\n\nCurrent backup contents:\n"$contents" " | mail -s "$overall_state: $kace_host Backup to $backup_host" $recipients

if [ $overall_state=="SUCCESSFUL" ]
then
    cleanup
    exit 0
else
    exit 1
fi
