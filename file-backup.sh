#!/usr/bin/env bash
#set -x


FAIL_CNT=0

function SHOW_HELP () {
  echo "HELP SCREEN : $0 backup <filename> <source_dir> <destination_dir>"
  echo " "
  echo "  Mandatory Option = backup "
  echo "  filename (OPTIONAL) = specifiy the filename that requires backup action, default: syslog"
  echo "  source_dir (OPTIONAL) = specifiy the absolute source directory for backup origin, default: /var/log/"
  echo "  destination_dir (OPTIONAL) = specify the absolute backup directory for backup storage, default: " $HOME"/backup"

}

function DO_BACKUP() {
  #echo "Doing Backup !!"
  FULL_BACKUP
  INCR_BACKUP
}

function FULL_BACKUP () {
  echo "## Starting Full Backup @ " `date +%H:%M:%S:%N` "##"
  rsync -a --inplace --no-whole-file $SOURCE_PATH$ORIG_FILE $BACKUP_PATH$BACKUP_FILE
  status=`echo $?`
  PREV_SIZE=`stat $SOURCE_PATH$ORIG_FILE | grep -i size | awk '{print $2}'`
  if [[ ($status -gt 0) && (FAIL_CNT -lt 3) ]]; then
    echo "Full Backup Failed, re-checking again"
    let FAIL_CNT++
    FULL_BACKUP
  elif [[ $status -gt 0 ]]; then
    exit 3
  else
    echo "..FULL Backup completed successfully @ " `date +%H:%M:%S:%N` 
  fi
}

function INCR_BACKUP () {
  echo "## Starting Incremental Backup ##"
  while :
  do
    echo "..Incremental Backup @ " `date +%H:%M:%S:%N`
    INCR_BCKP_FILE=$BACKUP_PATH$BACKUP_FILE-`date +%s`
    NEW_SIZE=`stat $SOURCE_PATH$ORIG_FILE | grep -i size | awk '{print $2}'`
    DIFF_SIZE=`expr $NEW_SIZE - $PREV_SIZE`
    tail -c +$PREV_SIZE $SOURCE_PATH$ORIG_FILE  | head -c $DIFF_SIZE >> $INCR_BCKP_FILE
    echo "..Incremental Backup Completed @ " `date +%H:%M:%S:%N`
    PREV_SIZE=`stat $SOURCE_PATH$ORIG_FILE | grep -i size | awk '{print $2}'`
    sleep 300
  done
}


if [[ $2 != "" ]]; then
  ORIG_FILE=$2
  BACKUP_FILE=$ORIG_FILE".bckp"
else
  ORIG_FILE="syslog"
  BACKUP_FILE=$ORIG_FILE".bckp"
fi

if [[ $3 != "" ]]; then
  SOURCE_PATH=$3
else
  SOURCE_PATH="/var/log/"
  #echo $SOURCE_PATH$ORIG_FILE
fi

if [[ $4 != "" ]]; then
  BACKUP_PATH=$4
else
  [ -d $HOME/backup ] || mkdir -p $HOME/backup
  BACKUP_PATH=$HOME/backup/
  #echo $BACKUP_PATH$BACKUP_FILE
fi

if [[ !(-z $1) && ($1 == "backup") ]]; then
  DO_BACKUP
else
  SHOW_HELP
fi
