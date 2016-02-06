#!/bin/bash

sudo kill $(ps aux | grep "node bin/xo-server" | grep -v grep | cut -d' ' -f8)

cd /opt/xo-server
git describe 
sleep 10s
sudo git pull
sudo npm i
sudo npm run build

cd /opt/xo-web
git describe
sleep 10s
sudo git pull
sudo npm i
sudo npm run build

sleep 15s

sudo shutdown -r now "System will reboot in 2 minutes to perform updates."
