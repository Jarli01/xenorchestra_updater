#!/bin/bash

updateFromSource ()
{
UPDATE=false

echo Current branch $(git rev-parse --abbrev-ref HEAD)
echo Current version $(git describe --abbrev=0)
sleep 5s

if [ "$BRANCH" != "" ]; then
	echo "Switching to branch '$BRANCH'..."
	sudo git diff-index --quiet HEAD -- || git stash -u && git stash drop
	sudo git checkout $BRANCH
fi

sudo git fetch origin -q
REMOTE=$(git rev-parse @{u})
REVISIONS=$( sudo git rev-list HEAD...$REMOTE --count )
echo $REVISIONS updates available

if [ $REVISIONS -ne 0 ] || [ "$FORCE" = true ]; then
  UPDATE=true
  echo "Updating from source..."
  sudo git diff-index --quiet HEAD -- || git stash -u && git stash drop
  sudo git pull
  echo "Clearing directories..."
  sudo rm -rf dist
fi
}

installUpdates()
{
  echo "Installing..."
  yarn
  yarn build
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

	updateYarn
	changeRepos
	
	UPDATE=""

	echo "Checking xen-orchestra..."
	cd /opt/xen-orchestra
	updateFromSource

	if [ "$UPDATE" = true ]; then
		echo "Adding existing plugins to Yarn lock file..."
		find node_modules -maxdepth 1 -type d -name 'xo-server-*' -printf '%P\0' | xargs -0 yarn upgrade
		sed -i 's/< 5/> 0/g' /opt/xen-orchestra/packages/xo-web/src/xo-app/settings/config/index.js
		sed -i 's/< 5/> 0/g' /opt/xen-orchestra/packages/xo-web/src/xo-app/xosan/index.js

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

updateYarn()
{
	echo "Checking for Yarn package..."

	if [ $(dpkg-query -W -f='${Status}' yarn 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
		echo "Installing Yarn..."
		curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
		echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
	else
		echo "Checking for Yarn update..."
	fi

	sudo apt-get update > /dev/null
	sudo apt-get install --yes yarn
}

changeRepos()
{	
	echo "Checking for Repo change..."
	
	if [ ! -d "/opt/xen-orchestra" ]; then
		cd /opt
		/usr/bin/git clone -b master https://github.com/vatesfr/xen-orchestra
		cp /opt/xo-server/.xo-server.yaml /opt/xen-orchestra/packages/xo-server/.xo-server.yaml
		mv xo-server xo-server.old
		mv xo-web xo-web.old
		sed -i 's:/opt/xo-server/:/opt/xen-orchestra/packages/xo-server/:g' /lib/systemd/system/xo-server.service
		systemctl daemon-reload
		FORCE=true
	fi
}

main "$@"

