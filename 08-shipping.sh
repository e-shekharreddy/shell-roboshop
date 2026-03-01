#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop" 
LOGS_FILE="/var/log/shell-roboshop/$0.log" 

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

dnf install maven -y &>>$LOGS_FILE
VALIDATE $? "Installing maven"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    VALIDATE $? "Adding system user" # $? == $1 and " <anything> " == $2 / # $? is $1 and " <anything> " considor as $2
else 
    echo -e "Roboshop user already exist ... $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "making app directory" # $? == $1 and " <anything> " == $2 / # $? is $1 and " <anything> " considor as $2

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading shipping code" # $? == $1 and " <anything> " == $2 / # $? is $1 and " <anything> " considor as $2

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/* &>>$LOGS_FILE
VALIDATE $? "Removing existing code"

unzip /tmp/shipping.zip &>>$LOGS_FILE
VALIDATE $? "Unzipping shipping code"





cd /app 
mvn clean package &>>$LOGS_FILE
VALIDATE $? "Installing and Building shipping"


mv target/shipping-1.0.jar shipping.jar &>>$LOGS_FILE
VALIDATE $? "Moving and renamaing"


cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOGS_FILE
VALIDATE $? "Created systtemctl service"

systemctl daemon-reload &>>$LOGS_FILE
VALIDATE $? "Reloaded Shipping"

dnf install mysql -y &>>$LOGS_FILE
VALIDATE $? "Installed MySQL"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities;' 

if [ $? -ne 0 ]; then 

    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOGS_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOGS_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOGS_FILE
    VALIDATE $? "Loaded data into MySQL"
else
    echo -e "Data already exist... $Y SKIPPING $N"
fi




systemctl enable shipping &>>$LOGS_FILE
systemctl start shipping
VALIDATE $? "Enabled and started Shipping"

systemctl restart shipping &>>$LOGS_FILE
VALIDATE $? "Restarted Shipping"



 
