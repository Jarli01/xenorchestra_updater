# Troubleshooting

If you are having problems, before you create an issue, please check the following. (You will be asked to provide this information anyways)

## Submitting a Support Request

Any issues, questions, or bugs during installation and usage of this script, that can not be solved by the steps below, should **first** be addressed in *this repository.* 

Xen-Orchestra (Community Edition) is not obligated to support scripted (or manual) builds. Please give us the ability to first troubleshoot the issue and/or verify this script is not the culprit before moving on to posting in the Xen-Orchestra [Community Forums](https://xen-orchestra.com/forum/).

Please use the [ISSUE TEMPLATE](https://github.com/Jarli01/xenorchestra_updater/issues/new) when submitting an issue.

## XO Website not loading

If the XO website fails to load please run the below command to determine if the primary service is running. 

       systemctl status xo-server.service
       
 A properly running system should look similar to this:
  
       	systemctl status xo-server.service
	● xo-server.service - XO Server
	   Loaded: loaded (/lib/systemd/system/xo-server.service; enabled; vendor preset
	   Active: active (running) since Wed 2018-04-11 08:51:41 EDT; 51s ago
	 Main PID: 710 (node)
		Tasks: 10 (limit: 4915)
	   Memory: 120.2M
		  CPU: 2.209s
	   CGroup: /system.slice/xo-server.service
			   └─710 /usr/local/bin/node ./bin/xo-server
       
## XO not updating or you're stuck on a specific version.     
       
If you ever get stuck on a specific revision of XO, or are receiving an alert saying "Please tell us who you are" from git you need to run the below:

       git config --global user.email "you@example.com"
       git config --global user.name "Your Name"
      
Provide your name and email address in the quoted sections, without quotes and once done try updating again. 

## Checking the logs

This will check and continually update the last 50 log files for your XOCE installation and thus is subject to any specific issues you're encountering. Just keep this command at the ready to check on things if you need too. 

       journalctl -u xo-server -f -n 50

## Required Dependencies 

Your system must be able to install the following list of dependencies, usually this is automatic but some distributions might not have the required repositories. Plese confirm you can install these before creating a ticket. 

Check your distribution respositories list ie: ```/etc/apt/sources.list``` for multiverse. 

* build-essential 
* redis-server 
* libpng-dev 
* git 
* python-minimal 
* libvhdi-utils 
* nfs-common
* lvm2
* cifs-utils

These dependencies (on Ubuntu) are available from the ```multiverse``` and ```universe``` repositories. 

## System Performance or General Errors Guidance

While XOCE can and does operate without issue for many people there are benefits to using using more than the absolute minimum system specifications for the guest OS. 

There is a mandate for 1 GB of ram built into the updater script. While this is a requirement of XO it isn't a requirement of the OS. 

An additional check is being considered to match the XOA system which is supplied with 2 CPU (or 1 CPU with 2 cores). While this currently isn't implemented; if you encounter issues please try adding an additional CPU to your installation and see if the issue persists. 
