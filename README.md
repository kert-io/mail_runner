#mail_runner
**WORK IN PROGRESS**. See Roadmap below for features not yet completed.

MailRunner acts as your mailman picking up your email from an [MTA](https://en.wikipedia.org/wiki/Message_transfer_agent), such as Postfix, and then delivering it directly to your app sending each email object as json to webhook.  You can tell it to deliver locally or send it to any active webhook making it a functional mailserver for several apps.

MailRunner, although packaged as a gem, only provides a [CLI](https://en.wikipedia.org/wiki/Command-line_interface).  You can launch one or several mailrunner bots via the CLI, daemonize them to run permanently or manage them using a process manager such as monit.  This also means, you can use it as a standalone ruby mail service alongside apps in any other language.

###Note: 
Mailrunner is designed for a very specific use case.  If you are looking for a gem to pull email from an existing regular old email account, via pop or imap, this is not the gem for you (check out [Mailroom](https://github.com/tpitale/mail_room)).  If you want a super simple setup that allows you to expose a number of different email addresses for recieving mail in your app, and the ability to suport new ones automatically, then MailRunner is for you.

###Requirements 
* Postfix MTA setup as to recieve email.  Basic setup instructions here. 

###Installation
``` 
gem install mailrunner
```

#Usage
Mailrunner is built with a CLI that is used to launch each bot. When in doubt about commands, add the -h flag. 
```
mailrunner -h
```

the basic commands

```
Usage: mail_runner [options]
    -m, --mailbox MAILBOX            Name of Mailbox to watch
    -w, --webhook URL                Complete url of webhook to deliver mail to
    -a, --archive                    Set to true id you want mail archived.
    -d, --daemon                     Daemonize process. Be sure to add logfile path.
    -L, --logfile                    Absolute path to log file.
    -c, --config                     Path to YAML config file.
    -v, --verbose                    Logger runs in debug mode.
```

The mailbox and webhook options are required; all others are optional.  

### basics
1 . To launch a basic mailrunner bot

```
mailrunner -m mailbox\_name -w http://127.0.0.1:3000/some_webhook_for_mail
```

* the mailbox_name is a registered account with postfix: i.e. a system account.  
	* Best to create these as users with no login privileges and no home directory.  You don't have to do it this way, but one less security issue to worry about and it's sole purpose is a mail pass-through anyway.  [Setup Instructions]().

* the webhook is any webhook. 
	* The example is a local path, but you can easily use any valid url.  The url MUST accept both the PUT and the HEAD http methods.  The HEAD is used to verify the url upon launching the bot. A simple HEAD example in sintra:

```
head '/some_webhook_for_mail' do
  status 200
end

```

2 . Mail is delivered as a standard POST request with a single parameter: mail_runner_event. Each email is a json encoded array with a single item containing a hash with key "msg".   Just recieve it, parse it and ...

```
post '/some_webhook_for_mail' do
  raw_message = params[:mail_runner_envelope]
  mail = JSON.parse(raw_message)[0]["msg"]
```

From there you can call all variables of the mail object with:
```
mail["key"]
```

### Format of the mail object
The format of the decoded json object is a:

keys | Value 
 --- | ------ 
**raw_msg**|	the full content of the email received.
**headers**| an array of the headers received for the email: ‘Dkim-Signature’, ‘Date’, ‘Message-Id’, etc.
**from_email**|	from email address 
**from_name**|	from name 
**to**|	all recipients
**email**|	email address where email was received
**subject**|	the subject line 
**tags**|	any tags applied
**sender**|	the Mandrill sender of the message
**text**|	text version of the email body
**html**|	HTML version of the email body
**attachments**|	an array of any attachments. If there are no attachments, key is omitted. See format below.
**images**|	an array of any images. If there are no attachments, key is omitted. See format below.	
**spam_report**|  -Coming Soon.  Requires postfix installation with clamAV.

&nbsp;

When images or attachments are included, each one will contain the following hash:

keys | Value 
 --- | ------ 
**name**| file name
**type**|	MIME type
**content**| raw content of file
**base64**|	boolean - Base64 encoded?

###Delayed Queue
If for any reason, mailrunner is not able to deliver the mail to the specified webhook, it will add it to the mailrunner mail queue to process later. The usual reason this occurs is the webhook is unresponsive, it returns an error code or the server is down. Mailrunner will intermittently test the server if this occurs and once it is working properly, it will process the queue.  If mail is not being delivered, you can check the mailrunner log for details on what is happening on mailrunners end.

## Additional Options
####Daemonize
 Use the `-d ` flag to turn mailrunner into a [daemon](https://en.wikipedia.org/wiki/Daemon_(computing)) & keep it running in the the background.  When running as a daemon, be sure to set the logfile path using the ` -L ` flag.

####Logging
  Mailrunner wil output all logging info to STDOUT if no logfile path is set.  

  To set a logfile path, use the `-L path/to/logfile.log ` flag followed by the absolute path to the logfile location.   If the file doesn't exist, it will be created, but the directory path must still be valid.

  Mailrunner logging is designed for leaving it running continuously in the background.  So the log doesn't become unusable, logs will automatically archive themselves in the same directory and start a new log each week.  
  
####archive
####Config

Mailrunner can also be launched with a config file storing all defaults in one place.  When using a config file, you can launch a mailrunner instance with `mailrunner -c /path/to/config.yml` leaving off all typically required flags.  [sample config file](https://gist.github.com/kert-io/3d8d24d048dd25801b7f)

When using a config file you can set your defaults in the config file but still override them for one-off instances using flags.  The instance will launch according to the config file, but override  only the options passed manually with each flag.

## Other usage Scenarios
####dtach
###Monit

  I prefer to use [Monit](https://mmonit.com/monit/) to manage my worker bots.  Why Monit?  Because I like working with native linux config files when working at the system level. (Many others try to blend conventions and I find it leads to holes in seeing your system and its bugs completely.) 
  
  Monit will monitor your daemonized processes, restart them in case of failure and dutifully sned you a notification or email with each action.  Makes it possible to pretty much start and walk away. (psst, it does a ton more too!!)
  
  You can tweak mailrunner to run with your preferred, but I offer the monit setup here:

**step 1 - Configure Upstart to manage mailrunner at the system service level**
  
  While monit monitors, [Upstart](http://upstart.ubuntu.com) is the native linux process for starting and stopping processes and keeping track of all system processes. 

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
    if mem is greater than 3% for 1 cycles then restart
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
	
	
#Roadmap
* Archiving
* Single bot managing several mailboxes and webhooks
* test server


#Testing
#Other helpful setup links
* Installing Postfix with spamassasin & clamav
* Setting up Postfix to work with mailrunner
* Setting up Monit to manage your mailrunner processes

#License
(The MIT License)

Copyright (c) 2015 Kert Heinecke

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

