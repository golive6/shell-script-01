#!/bin/bash

source ./common.sh
check_root

echo "Please enter DB password:"
read mysql_root_password

dnf module disable nodejs -y &>>$LOGFILE
VALIDATE $? "Disabling default nodejs."

dnf module enable nodejs:20 -y &>>$LOGFILE
VALIDATE $? "Enabling nodejs:20 version."

dnf install nodejs -y &>>$LOGFILE
VALIDATE $? "Installing nodejs."

id expense &>>$LOGFILE
if [ $? -ne 0 ]
then 
    useradd expense &>>$LOGFILE
    VALIDATE $? "Creating expense user"
else
    echo -e "Expense user already created....$Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOGFILE
VALIDATE $? "Downloading backend code"

cd /app
rm -rf /app/*
unzip /tmp/backend.zip &>>$LOGFILE
VALIDATE $? "Extracted backend code"

npm install &>>$LOGFILE

cp /home/ec2-user/shell-script-01/backend.service /etc/systemd/system/backend.service &>>$LOGFILE
VALIDATE $? "Copied backend service file"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Daemon reload"

systemctl start backend &>>$LOGFILE
VALIDATE $? "Starting backend"

systemctl enable backend &>>$LOGFILE
VALIDATE $? "Enbaling backend"

dnf install mysql -y &>>$LOGFILE
VALIDATE $? "Installing MySQL Client"

mysql -h db.goliexpense.online -uroot -p${mysql_root_password} < /app/schema/backend.sql &>>$LOGFILE
VALIDATE $? "Schema laoding"

systemctl restart backend &>>$LOGFILE
VALIDATE $? "Restarting backend"






