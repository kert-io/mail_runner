##Monit Setup for Mailrunner
This describes the process of setting up Monit to manage your mailrunner instance.

**NOTE:** before setting up or starting Monit, test manually with desired config file settings!! Monitors conceal stdout messages which is how mailrunner communicates immediately if your config file has an error. 

**step 1 - Configure Upstart to manage mailrunner at the system service level**
  
  While monit monitors, it uses Upstart control processes directly. [Upstart](http://upstart.ubuntu.com) is the native linux process for starting and stopping processes and keeping track of all system processes. 

* navigate to init folder where all Upstart config files are stored. Create a new .conf file for mailrunner & open it with text editor:
      
 ```sh
 cd /etc/init
 sudo touch mailrunner.conf
 sudo vim mailrunner.conf
 ```
 
* Paste the following inside the .conf file. Substitute your username into the setuid & HOME variables in the User Variables section to suit your deployment and save. 
	* **setuid** - login name of user account you used when installing mailrunner. 
	* **HOME** - Note this is to locate your locally installed gems using rbenv. You can also modify uncomment th global install setup included as well.

	```sh
	#   sudo start mailrunner
	#   sudo stop mailrunner
	#   sudo status mailrunner
	#
	#   or use the service command:
	#   sudo service mailrunner {start,stop,restart,status}
	
	description "Upstart control over MailRunner bots. From ruby gem mail_runner"
	
	# no "start on", we don't want to automatically start
	stop on (runlevel [06])
	
	##########################################
	# change to match your deployment user
	setuid username
	env HOME="/home/username"
	############################################
	script
	# this script runs in /bin/sh by default
	# respawn as bash so we can source in rbenv
	exec /bin/bash <<'EOT'
	
	# pull in system rbenv
	# source /etc/profile.d/rbenv.sh
	# or 
	# pull in user installed rbenv
	  export PATH="$HOME/.rbenv/bin:$PATH"
	  eval "$(rbenv init -)"
	  export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"
	
	#launch mailrunner
	  exec mail_runner -c $HOME/mailrunner_config.yml
	
	EOT
	end script
	```
       
   * You can now start and stop mailrunner with the the following system level commands:
   
   ```sh
   sudo start mailrunner
   sudo stop mailrunner
   sudo restart mailrunner
   ```

   * NOTE: You must use the Mailrunner Config file to use Upstart and Monit.  See Mailrunner config section above.  This Upstart config assumes you store the mailrunner_config.yml file in your home directory.
   
**step 2 - Install and set up Monit to monitor & manage Mailrunner**

* Install Monit. see this [gist]() for guidance

With Monit installed, it is easy to set it up to monitor Mailrunner. Monit stores the config files for each process it monitors in the conf.d folder.

* navigate to conf.d folder. Create a new conf file for mailrunner & open it with text editor:

	```sh
	cd /etc/monit/conf.d
	sudo touch mailrunner
	sudo vim mailrunner
	```
* Paste the following inside the .conf file & save. You can modify the triggers to suit your workload and resource allocation, but best to just let it run and watch it for a while and fine tune it for you setup.

	```sh
	 # mailrunner
  	check process mailrunner
   	with matching mail_runner
   	
   	start program = "/bin/bash -c 'start mailrunner'"
   	stop program = "/bin/bash -c 'stop mailrunner'"
   	
   	#process monitor triggers
    if cpu is greater than 10% for 2 cycles then alert
    if mem is greater than 5% for 1 cycles then restart
    if 3 restarts within 5 cycles then timeout
	```
	
* reload monit settings to pull in your new config

	```sh
	sudo monit reload
	```
* Start mailrunner using monit.  Check status to see it initializing

	```sh
	sudo monit start mailrunner
	sudo monit status
	```
*  Monit has a ton more features like alerts & notifications.  I highly recommend setting these up and monit will let you know whenever it needs your attention.  Now, relax;-)