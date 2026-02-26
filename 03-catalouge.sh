#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop" # full path
LOGS_FILE="/var/log/shell-roboshop/$0.log" # or we can write it as $LOGS_FOLODER/$0.log

R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"

if [ $USERID -ne 0 ]; then
    echo -e " $R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1
fi 

mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2... $R FAILURE $N " | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2... $G SUCCESS $N " | tee -a $LOGS_FILE
    fi
}

dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "Disabling NodeJS Default version" # $? = privious command output and " <anything> " == $2 / # $? is $1 and " <anything> " considor as $2

dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "Enabling NodeJS:20" # $? == $1 and " <anything> " == $2 / # $? is $1 and " <anything> " considor as $2

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Install NodeJS" # $? == $1 and " <anything> " == $2 / # $? is $1 and " <anything> " considor as $2

id roboshop &>>$LOGS_FILE
if [ $? ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    VALIDATE $? "Adding system user" # $? == $1 and " <anything> " == $2 / # $? is $1 and " <anything> " considor as $2
else 
    echo -e "Roboshop user already exist ... $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "making app directory" # $? == $1 and " <anything> " == $2 / # $? is $1 and " <anything> " considor as $2

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading Catalouge code" # $? == $1 and " <anything> " == $2 / # $? is $1 and " <anything> " considor as $2

