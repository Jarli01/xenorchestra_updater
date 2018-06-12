#!/bin/bash

updateFromSource ()
{
UPDATE=false

echo Current branch $(git rev-parse --abbrev-ref HEAD)
GetVersions
echo Current version $XOS_VER / $XOW_VER

sleep 5s

#Check Git user/email for installer
gituser=$(git config --global user.name)
gitemail=$(git config --global user.email)
if [ -z "$gituser" ] || [ -z "$gitemail" ]; then
	echo "Git credentials required to run XOCE updater";
	echo "enter your credentials with the following commands and then rerun this update script"
	echo "git config --global user.email "you@example.com""
	echo "git config --global user.name "Your Name""
	exit 1;
fi

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
  GetVersions
  echo Updated version $XOS_VER / $XOW_VER
}

installPlugins()
{
  echo "Checking plugins..."

  # symlink any missing plugins
  dest=/usr/local/lib/node_modules/
  for source in =$(ls -d /opt/xen-orchestra/packages/xo-server-*); do
    plugin=$(basename $source)
    if [ ! -L $dest$plugin ];  then
      echo "Creating link for $plugin"
      ln -s "$source" "$dest"
    fi
done
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
		sed -i 's/< 5/> 0/g' /opt/xen-orchestra/packages/xo-web/src/xo-app/settings/config/index.js
		sed -i 's/< 5/> 0/g' /opt/xen-orchestra/packages/xo-web/src/xo-app/xosan/index.js

		installUpdates
		installPlugins
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

	if [ -d "/opt/xo-server" ]; then
		cd /opt
		/usr/bin/git clone -b master https://github.com/vatesfr/xen-orchestra
		cp /opt/xo-server/.xo-server.yaml /opt/xen-orchestra/packages/xo-server/.xo-server.yaml
		mv xo-server xo-server.old
		sed -i 's:/opt/xo-server/:/opt/xen-orchestra/packages/xo-server/:g' /lib/systemd/system/xo-server.service
		systemctl daemon-reload
		FORCE=true
	fi

	if [ -d "/opt/xo-web" ]; then
		mv xo-web xo-web.old
		sed -i 's:/opt/xo-web/dist:/opt/xen-orchestra/packages/xo-web/dist:g' /opt/xen-orchestra/packages/xo-server/.xo-server.yaml
		FORCE=true
	fi

}

GetVersions()
{
	if [ -f "/opt/xen-orchestra/packages/xo-server/package.json" ]; then
		XOS_VER=$(node -pe "require('/opt/xen-orchestra/packages/xo-server/package.json').version")
	fi

	if [ -f "/opt/xen-orchestra/packages/xo-web/package.json" ]; then
		XOW_VER=$(node -pe "require('/opt/xen-orchestra/packages/xo-web/package.json').version")
	fi
}

main "$@"
