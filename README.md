#mail_runner

[![Gem Version](https://badge.fury.io/rb/mail_runner.svg)](https://badge.fury.io/rb/mail_runner) [![Code Climate](https://codeclimate.com/github/kert-io/mail_runner/badges/gpa.svg)](https://codeclimate.com/github/kert-io/mail_runner)

MailRunner acts as your mailman picking up your email from an [MTA](https://en.wikipedia.org/wiki/Message_transfer_agent), such as Postfix, and delivering it directly to your app sending each email object in json format to a webhook.  You can tell it to deliver locally or send it to any active webhook making it a functional mailserver for several apps.

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
mail_runner -h
```
Don't forget to restart your terminal or the cli will not work!!

**the basic commands**

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
mail_runner -m mailbox_name -w http://127.0.0.1:3000/some_webhook_for_mail
```

* the mailbox_name is a registered account with postfix: i.e. a Linux system account.  
	* Best to create these as users with no login privileges and no home directory.  You don't have to do it this way, but it's one less security issue to worry about and it's sole purpose is a mail pass-through anyway.  Oh, and it is super simple: [Setup Instructions](https://github.com/kert-io/mail_runner/tree/master/gists/no-login_user.md).

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
###Daemonize
 Use the `-d ` flag to turn mailrunner into a [daemon](https://en.wikipedia.org/wiki/Daemon_(computing)) & keep it running in the the background.  When running as a daemon, be sure to set the logfile path using the ` -L ` flag.

###Logging
  Mailrunner wil output all logging info to STDOUT if no logfile path is set.  

  To set a logfile path, use the `-L path/to/logfile.log ` flag followed by the absolute path to the logfile location.   If the file doesn't exist, it will be created, but the directory path must still be valid.

  Mailrunner logging is designed for leaving it running continuously in the background.  So the log doesn't become unusable, logs will automatically archive themselves in the same directory and start a new log each week.  
  
###Archive
Alongside delivery to any webhook hook, Mailrunner also supports archiving your emails. Beyond archival purposes, this is super convenient for chasing down bugs, feature testing, and system error recovery. Mailrunner can archive locally or to a cloud storage device.  Mailrunner currently supports AWS & Rackspace. 

Use the Config file option when using the archive feature to simplify passing archive parameters to mailrunner.  Archive option notes are included directly in the [sample config file](https://github.com/kert-io/mail_runner/tree/master/gists/mailrunner_config.yml)

**File Naming**
All archived messages are saved as json and use the unique message-id as the file name. (NOTE: All illegal file system characters have been replaced with underscores; check the message-id in the message header section when seeking the actual id.) 

When looking for an archived copy of a message, you must locate it by the message-id.  To do so, run the id through the same name-scrubbing process used during the archive process: `/[#<$+%>!&*?=\/:@]/` are replaced with '_'.

**NOTE** When using Rackspace, the Fog gem (OS ruby cloud library) used by mailrunner has a [memory leak that is still unresolved](https://github.com/fog/fog/issues/3442). Until it is, I recommend using Monit to keep tabs on this and restart as needed.  Test for a few days & tune Monit for your usage levels.

###Config File

Mailrunner can also be launched with a config file storing all defaults in one place.  When using a config file, you can launch a mailrunner instance with `mailrunner -c /path/to/config.yml` leaving off all typically required flags.  [sample config file](https://github.com/kert-io/mail_runner/tree/master/gists/mailrunner_config.yml)

When using a config file you can set your defaults in the config file but still override them for one-off instances using flags.  The instance will launch according to the config file, but override  only the options passed manually with each flag.

## Other usage Scenarios
###Monit

I prefer to use [Monit](https://mmonit.com/monit/) to manage my worker bots.  Why Monit?  Because I like working with native linux config files when working at the system level. (Many others try to blend conventions and I find it leads to holes in seeing your system and its bugs completely.) 
  
Monit will monitor your daemonized processes, restart them in case of failure and dutifully send you a notification or email with each action.  It makes it possible to pretty much start a process and walk away. (psst, it does a ton more too!!)
  
You can tweak mailrunner to run with your preferred monitor, but I offer the [monit setup here](https://github.com/kert-io/mail_runner/tree/master/gists/monit_setup.md).

## Important Postfix Settings & Tips
###File Lock Setup
For testing mailrunner out, the basics are all you need.  Before using in production, you will need to sync postfix and Ruby file lock systems. [Here's how](https://github.com/kert-io/mail_runner/tree/master/gists/file_lock_sync.md)

###Mailbox Type
By default, postfix uses the **mbox** format for storing emails it recieves.  This is the format mailrunner expects, so you you are just getting set up, you are good by default.  You can check your mailbox with the `postconf` command.  If you see `home_mailbox = Maildir/` you will need to reset this with `postconf -e home_mailbox =`.(blank signals default) 

###Aliases
Create unlimited number email addresses internal to your app with just a few lines of configuration. 

Aliases are used by Postfix to direct mail to the appropriate mailbox. But we can also create virtual domains and sub-domains and then point them all to a single local user mailbox.  If we have mailrunner set to pick up mail at this user mailbox, then it will pick up all mail sent to these sub-domains.

This catchall approach leaves all mail sorting to the app itself which is super simple when emails are delivered as json.  Once you have mailrunner set to pick up mail from a mailbox, in this case 'my_mailbox' you just need to tell postfix to deliver all mail for the desired sub-domain to my_mailbox.

Navigate to the postfix directory

```
cd /etc/postfix
```

open virtual with `sudo vim virtual` and add the following(change to fit your instance) 

```
#catchall format -> all for sub-domain delivered to my_mailbox 
@post.sub.domain.com: my_mailbox
```
then update the virtual mapping with

```
sudo postmap /etc/postfix/virtual
```

Now we have to tell post fix to use the vitural domain & mapping by adding the following to main.cf

```
virtual_alias_domains = post.sub.domain.com,
virtual_alias_maps = hash:/etc/postfix/virtual
```
Finally, reload postfix for the changes to take effect

```
sudo service postfix reload
```

Thats it.  You can now sort all emails on the backend and new email addresses can be created on the fly for that sub-domain without ever needing to register each email address with postfix. 


#Roadmap
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

