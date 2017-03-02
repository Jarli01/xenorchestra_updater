# xenorchestra_updater

A simple tool to pull Xen Orchestra updates and apply the settings to your XO installation.


## Options

| Param | Action           | Argument  |
|:-----:|:----------------|------|
|  -f   | Force rebuild |
|  -b   | Switch git branch | stable \| next-release    |
|  -n   | Change node version  | lts \| stable \| 4.5.0      |

## Production Operations - Staying current
Basic usage, force rebuild, switch branch are the preferred operations, as you'll stay current with us. 

### Basic usage
```
sudo bash
<password>
sudo curl https://raw.githubusercontent.com/Jarli01/xenorchestra_updater/master/xo-update.sh | bash
```

### Force rebuild
```
sudo bash
<password>
sudo curl https://raw.githubusercontent.com/Jarli01/xenorchestra_updater/master/xo-update.sh | bash -s -- -f 
```

### Switch branch
```
sudo bash
<password>
sudo curl https://raw.githubusercontent.com/Jarli01/xenorchestra_updater/master/xo-update.sh | bash -s -- -b next-release
```

### Update Node
```
sudo bash
<password>
sudo curl https://raw.githubusercontent.com/Jarli01/xenorchestra_updater/master/xo-update.sh | bash -s -- -n stable
```

### Installing Yarn
Yarn is a required dependency of XO as of (March 2017) this is a one time operation and not to be used repeatedly. 
```
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - 
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install yarn
```

### Basic operation (without updating the local update script - local testing)

``` sudo ./xo-update -f``` to force a clean installation

``` sudo ./xo-update -b next-release```  to switch to "next-release" branch 
