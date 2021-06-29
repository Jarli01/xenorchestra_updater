#!/bin/bash

# Plugins to ignore
ignoreplugins=("xo-server-test")

updateFromSource ()
{
UPDATE=false

echo Current branch $(git rev-parse --abbrev-ref HEAD)
GetVersions
echo Current version $XOS_VER / $XOW_VER
echo Current $XO_COMMIT
sleep 5s

if [ "$BRANCH" != "" ]; then
	echo "Switching to branch '$BRANCH'..."
	git diff-index --quiet HEAD -- || git stash -u && git stash drop
	git checkout $BRANCH
fi

git fetch origin -q
REMOTE=$(git rev-parse @{u})
REVISIONS=$( git rev-list HEAD...$REMOTE --count )
echo $REVISIONS updates available

if [ $REVISIONS -ne 0 ] || [ "$FORCE" = true ]; then
  UPDATE=true
  echo "Updating from source..."
  git diff-index --quiet HEAD -- || git stash -u && git stash drop
  git pull
  git clean -d -f -q
  echo "Clearing directories..."
  rm -rf dist
fi
}

installUpdates()
{
  echo "Installing..."
  yarn
  yarn build
  GetVersions
  echo Updated version $XOS_VER / $XOW_VER
  echo Updated $XO_COMMIT
}

installPlugins()
{
  echo "Checking plugins..."

  # symlink any missing plugins
  dest=/usr/local/lib/node_modules/
  for source in $(ls -d /opt/xen-orchestra/packages/xo-server-*); do
    plugin=$(basename $source)

    if [[ "${ignoreplugins[@]}" =~ $plugin ]]; then
      echo "Ignoring $plugin plugin"
    elif [ ! -L $dest$plugin ];  then
      echo "Creating link for $plugin"
      ln -s "$source" "$dest"
    fi
  done
}

cleanupPlugins()
{
  echo "Cleanup plugins..."
  dest=/usr/local/lib/node_modules
  
  # Remove links to non-existent plugins
  find $dest/xo-server-* -xtype l -delete

  # Remove other "bad" links
  for plugin in "${ignoreplugins[@]}"; do
    if [ -L $dest/$plugin ]; then
      echo "Removing link for $plugin"
      rm $dest/$plugin
    fi
  done
}

main() {
	if [ "$EUID" -ne 0 ]; then
		echo "Please run as root (sudo bash | su)"
		exit
	fi

	#Check Git email
	gitemail=$(git config --global user.email)
	if [ -z "$gitemail" ]; then
		echo "Git email required to run XOCE updater";
		echo "enter your credentials with the following commands and then rerun this update script"
		echo "git config --global user.email \"you@example.com\""
		exit 1;
	fi

	#Check Git name
	gituser=$(git config --global user.name)
	if [ -z "$gituser" ]; then
		echo "Git name required to run XOCE updater";
		echo "enter your credentials with the following commands and then rerun this update script"
		echo "git config --global user.name \"Your Name\""
		exit 1;
	fi

	totalk=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
	if [ "$totalk" -lt "3000000" ]; then echo "XOCE Requires at least 3GB Memory!"; exit 1; fi 

	while getopts b:fn: opt; do
		case $opt in
			b)
				BRANCH="$OPTARG"
				FORCE=true

				if [ "$BRANCH" == "" ]; then
					BRANCH="master"
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

	# Get current node version
	nodeVersion=$(node -v  | cut -d"v" -f2)

	# Get LTS node version
	nodeLTS=$(n --lts)

	if [ "$nodeVersion" != "$nodeLTS" ] && [ "$NODE" != true ]; then
		echo "Incorrect version of Node detected";
		echo "Update node with the following command and then rerun this script"
		echo "sudo n lts"
		exit 1;
	fi

	echo "Stopping xo-server..."
	ISACTIVE=$(systemctl is-active xo-server)
	if [ "$ISACTIVE" == "active" ]; then
	  systemctl stop xo-server
	else
	  pkill -f "/bin/xo-server"
	fi

	if [ "$NODE" = true ]; then
		echo "Updating Node.js to '$VERSION' version..."
		n "$VERSION"
	fi

	updateYarn
	updateDependencies
	changeRepos

	UPDATE=""

	echo "Checking xen-orchestra..."
	cd /opt/xen-orchestra
	updateFromSource

	if [ "$UPDATE" = true ]; then
		installUpdates
		installPlugins
		cleanupPlugins
	fi

	fixupService
	sleep 5s

	if [ "$ISACTIVE" == "active" ]; then
	  echo "Restarting xo-server..."
	  systemctl start xo-server
	else
	  echo "Please manually restart xo-server"
	fi
}

updateYarn()
{
	echo "Checking for Yarn package..."

	if [ $(dpkg-query -W -f='${Status}' yarn 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
		echo "Installing Yarn..."
		echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
	else
		echo "Checking for Yarn update..."
	fi

	curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
	apt-get update > /dev/null
	apt-get install --yes yarn
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
	
	XO_COMMIT=$(git rev-list --format=format:'%ai' --max-count=1 `git rev-parse HEAD`)
}

updateDependencies()
{
	echo "Checking for missing dependencies..."
	declare -a depends=("lvm2" "cifs-utils")

	for i in "${depends[@]}"
	do
		if [ $(dpkg-query -W -f='${Status}' $i 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
			echo "Installing $i..."
			apt-get install --yes $i
		fi
	done
}

fixupService()
{
	sed -i 's:./bin/xo-server:./dist/cli.mjs:g' /lib/systemd/system/xo-server.service
	systemctl daemon-reload
}

main "$@"

