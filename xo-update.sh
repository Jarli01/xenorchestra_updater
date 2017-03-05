#!/bin/bash

updateFromSource ()
{
UPDATE=false

echo Current branch $(git rev-parse --abbrev-ref HEAD)
echo Current version $(git describe --abbrev=0)
sleep 5s

if [ "$BRANCH" != "" ]; then
	#echo "Switching to branch '$BRANCH'..."
	sudo git checkout $BRANCH
fi

sudo git fetch origin -q
REMOTE=$(git rev-parse @{u})
REVISIONS=$( sudo git rev-list HEAD...$REMOTE --count )
echo $REVISIONS updates available

if [ $REVISIONS -ne 0 ] || [ "$FORCE" = true ]; then
  UPDATE=true
  echo "Updating from source..."
  sudo git stash -u
  sudo git pull
  echo "Clearing directories..."
  sudo rm -rf dist
  cd node_modules
  find * -maxdepth 0 -name 'xo-server-*' -prune -o -exec rm -rf {} \; 
  cd ..
fi
}

installUpdates()
{
  echo "Installing..."  
  yarn install --force
  echo Updated version $(git describe --abbrev=0)
}

main() {
	if [ "$EUID" -ne 0 ]; then
		echo "Please run as root (sudo bash)"
		exit
	fi

	while getopts b:fn: opt; do
		case $opt in
			b)
				BRANCH="$OPTARG"
				FORCE=true
				
				if [ "$BRANCH" == "" ]; then
					BRANCH="stable"
				fi;;
				
			f)	FORCE=true;;

			n)
				NODE=true
				FORCE=true
				VERSION="$OPTARG"
				
				if [ "$VERSION" == "" ]; then
					VERSION="lts"
				fi;;
		esac
	done

	echo "Stopping xo-server..."
	ISACTIVE=$(systemctl is-active xo-server)
	if [ "$ISACTIVE" == "active" ]; then
	  sudo systemctl stop xo-server
	else
	  sudo pkill -f "/bin/xo-server"
	fi

	if [ "$NODE" = true ]; then
		echo "Updating Node.js to '$VERSION' version..."
		sudo n "$VERSION"
	fi

	UPDATE=""
	
	echo "Checking xo-server..."
	cd /opt/xo-server
	updateFromSource
	
	if [ "$UPDATE" = true ]; then
		installUpdates
	fi
	
	echo "Checking xo-web..."
	cd /opt/xo-web
	updateFromSource
	if [ "$UPDATE" = true ]; then
		sed -i 's/< 5/> 0/g' /opt/xo-web/src/xo-app/settings/config/index.js
		sed -i 's/< 5/> 0/g' /opt/xo-web/src/xo-app/xosan/index.js
		installUpdates
	fi
	
	sleep 5s

	if [ "$ISACTIVE" == "active" ]; then
	  echo "Restarting xo-server..."
	  sudo systemctl start xo-server
	else
	  echo "Please manually restart xo-server"
	fi
}

main "$@"
