# xenorchestra_updater

A simple tool to pull 'next-release' or 'stable' Xen Orchestra updates and apply the settings to your XO installation.

## Options

| Param | Action           | Argument  |
|:-----:|:----------------|------|
|  -f   | Force rebuild |
|  -b   | Switch git branch | stable \| next-release    |
|  -n   | Change node version  | lts \| stable \| 4.5.0      |

## Examples

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
