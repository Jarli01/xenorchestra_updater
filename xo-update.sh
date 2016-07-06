#!/bin/bash

updateFromSource ()
{
echo Current branch $(git rev-parse --abbrev-ref HEAD)
echo Current version $(git describe --abbrev=0)
sleep 10s
sudo git fetch origin -q
REMOTE=$(git rev-parse @{u})
output=$( sudo git rev-list HEAD...$REMOTE --count )
echo $output updates available

if [[ $output -ne 0 ]]; then
  echo "Updating from source..."
  sudo git pull
  sudo rm -rf dist
  sudo rm -rf node_modules
  sudo npm i
  sudo npm run build
  echo Updated version $(git describe --abbrev=0)
fi
}

echo "Stopping xo-server..."
isActive=$(systemctl is-active xo-server)
if [ "$isActive" == "active" ]; then
  sudo systemctl stop xo-server
else
  sudo pkill -f "/bin/xo-server"
fi

echo "Updating Node.js to latest stable version..."
sudo n stable

echo "Checking xo-server..."
cd /opt/xo-server
updateFromSource

echo "Checking xo-web..."
cd /opt/xo-web
updateFromSource

sleep 5s

if [ "$isActive" == "active" ]; then
  echo "Restarting xo-server..."
  sudo systemctl start xo-server
else
  echo "Please manually restart xo-server"
fi
