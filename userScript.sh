#!/bin/bash
cd /
cd /home/ubuntu/new_chatapp/fundoo/fundoo
sudo echo > .env
sudo echo "PORT = '3306'" >> .env
sudo echo "DB_HOST = 'terraform-20210602192934368700000001.cyxq3nw89gci.ap-south-1.rds.amazonaws.com'" >> .env
sudo echo "DB_USER = 'shiv'" >> .env
sudo echo "DB_PASS = 'shiv12345'" >> .env
sudo echo "DB_NAME = 'shiv'" >> .env
sudo systemctl enable chatapp.service 
sudo systemctl restart chatapp.service

