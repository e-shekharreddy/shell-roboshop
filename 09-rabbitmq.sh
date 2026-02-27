#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop" # full path
LOGS_FILE="/var/log/shell-roboshop/$0.log" # or we can write it as $LOGS_FOLODER/$0.log

R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m" 
N="\e[0m"

SCRIPT_DIR=$PWD
MONGODB_HOST="mongodb.tsmvr.fun"
MYSQL_HOST="mysql.tsmvr.fun"

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

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOGS_FILE
VALIDATE $? "Copied repos"

dnf install rabbitmq-server -y &>>$LOGS_FILE
VALIDATE $? "Installing rabbitmq Server"

systemctl enable rabbitmq-server &>>$LOGS_FILE
systemctl start rabbitmq-server
VALIDATE $? "Enabled and started rabbitmq Server"

if [ $? -ne 0 ]; then
    rabbitmqctl add_user roboshop roboshop123
    rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
    VALIDATE $? "created user and given permissions"
else
    echo -e "User already exist... $Y SKIPPING $N"
fi


systemctl restart rabbitmq-server
VALIDATE $? "Restarted rabbitmq Server"