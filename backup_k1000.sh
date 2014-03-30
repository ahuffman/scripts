#!/bin/bash

#------------------------------------------------------------------#
#  Written by: Andrew J. Huffman - andrew.j.huffman@gmail.com      #
#     March 2014                                                   # 
#------------------------------------------------------------------#
#  Purpose: To backup Dell KACE k1000 database and package files   #
#  Setup:  --------------------------------------------------------#
#      1. Fill in appropriate values for your environment          #
#      2. Add to your crontab for scheduled backups                #
#  Requires:  -----------------------------------------------------#
#         1. Curl package be installed on your server              #
#         2. FTP enabled k1000                                     #
#         3. FTP password set for k1000                            #
#******************************************************************#

#Setup:
recipients="your comma separated email list"
bkup_path=/your/backup/path/
kace_host="your fqdn hostname"
password="your k1000 ftp password"
log=/your/log/path/backup_k1000_lastrun.log
backup_host="your backup server's hostname"
days_to_keep=3  #Remove anything older than this number of days
#End Setup

#Static
DATE=`date +"%Y%m%d"`

#Functions
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
  #Cleans up backups older than X days
  find $bkup_path -mtime +$days_to_keep -delete
}


#Start work
  #K1000 DataBase
    echo "Starting K1000 Backup of DB DATA"
    curl -u kbftp:$password ftp://$host/kbox_dbdata.gz -o "$bkup_path""$DATE"_kbox_dbdata.gz
    #collect result
      dbstatus=$?
      dbstate=`check_status $dbstatus`
      
  #K1000 FileData (packages)
    echo "Starting K1000 Backup of FILE DATA"
    curl -u kbftp:$password ftp://$kace_host/kbox_file.tgz -o "$bkup_path""$DATE"_kbox_file.tgz
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
    	#Don't cleanup, because we haven't maintained 3 days worth of backups
        exit 1
    fi
