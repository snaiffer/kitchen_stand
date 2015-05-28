#!/bin/bash 

expect -c " spawn su -c \"service aksusbd stop\"; expect \"Пароль: \" {send \"redhat\r\"}; sleep 1 "
