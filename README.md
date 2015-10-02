#MailRunner Gem
This is the start of a gem.  The gem will include:

* a worker process that can be run outside of & separate from app and will grab mail from local MTA(assumes postfix) and delivers it to an http endpoint you specify.
* Several helper methods for parsing, manipulating and archiving emails.
* A simple outbound templating & sending interface.