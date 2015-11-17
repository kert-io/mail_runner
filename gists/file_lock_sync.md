##Syncing file lock protocols for Ruby & Postfix.

Getting Ruby and Postfix on the same page is an important step in getting mailrunner properly setup.

There are three available linux locking mechanisms in Postfix: flock, dotlock & fcntl. The Ruby File class uses the **flock** method. Given Ruby's limitations here, we will set Postfix to respect flock.

##Setup Postfix to use flock locking mechanism

* Postfix by default is set to use dotlock and fcntl.
	* to see current postfix settings, `postconf`
	* to see default postfix lock settings can be seen with `postconf -d`:
	
The one to look for is:
```
mailbox_delivery_lock = fcntl, dotlock
```
Set postfix delivery lock to include flock with:

```
sudo postconf -e 'mailbox_delivery_lock = flock, fcntl, dotlock`
```	
This will tell postfix to respect all three file locking protocols. You can confirm the setting by running the `postconf` command again and checking the mailbox\_delivery\_lock.  

Reload postfix config with 
```
sudo postfix reload
```
Ruby and postfix are now on the same page.

\* alternative method for setting mailbox\_delivery\_lock - You can add 	`mailbox_delivery_lock = fcntl, dotlock` to bottom of `/etc/postfix/main.cf` The method used above does this anyway, so you can always go undo indivudal settings there.

	

