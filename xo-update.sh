#!/bin/bash

updateFromSource ()
{
echo Current version $(git describe --abbrev=0)
sleep 10s
sudo git fetch origin
REMOTE=$(git rev-parse @{u})
output=$( sudo git rev-list HEAD...$REMOTE --count )
echo $output updates available

if [[ $output -ne 0 ]]; then
  echo "Updating from source..."
  sudo git pull
  sudo npm i
  sudo npm run build
  echo Updated version $(git describe --abbrev=0)
fi
}

isActive=$(systemctl is-active xo-server)
if [ "$isActive" == "active" ]; then
  sudo systemctl stop xo-server
else
  sudo pkill -f "/bin/xo-server"
fi

echo "Checking xo-server..."
cd /opt/xo-server
updateFromSource

echo "Checking xo-web..."
cd /opt/xo-web
updateFromSource

sleep 15s

sudo shutdown -r now "System will reboot now to perform updates."
