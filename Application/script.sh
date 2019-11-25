#!/bin/bash

BUCKETNAME="eran-tf-nginx-bucket"
LOGDIR="/var/log/nginx"
LOGDATE=$(date +"%Y-%m-%d-%s")
HOST=$(wget -q -O- http://169.254.169.254/latest/meta-data/instance-id)
IP=$(wget -q -O- http://169.254.169.254/latest/meta-data/public-ipv4)
LOGFILES=("access")

echo "Moving access logs to dated logs.."

for LOGFILE in "${LOGFILES[@]}"
do
  CURFILE="$LOGDIR/$LOGFILE.log"
  NEWFILE="$LOGDIR/$LOGFILE-$LOGDATE.log"
  mv $CURFILE $NEWFILE
done

echo "done!.."


echo "Sending rotate signal to nginx.."

NGINX_MASTER_PID=`ps aux | grep nginx | grep master | awk '{ printf $2" "}'`

kill -USR1 $NGINX_MASTER_PID

echo "done!.."

sleep 1

echo "Uploading log files to s3.."

for LOGFILE in "${LOGFILES[@]}"
do
  FILENAME="$LOGFILE-$LOGDATE.log"
  FILE="$LOGDIR/$FILENAME"
#  gzip $FILE
  s3cmd put $FILE s3://$BUCKETNAME/$IP/$FILENAME
#  rm $FILE.gz
  rm $FILE
done

echo "done!.."
