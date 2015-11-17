##Create a system user account with no-login
This describes the steps for creating a Linux user with no home directory and no-login priveleges.  This process is illustrated here for use as an inaccessible mail reciever account.  See [Mailrunner Gem](https://github.com/kert-io/mail_runner) for more info on the use case.

* Create a user without home file directory
```  
 sudo useradd -r <name>
 ```
* Turn off login for this user.
```
sudo usermod -s /bin/false talkpost
```
* Confirm the setting
```
sudo cat /etc/passwd
```

You should see a line with the username that ends with :/bin/false.