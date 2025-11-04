**As any other Powershell file, you might need to unlock this one before opening through RMB > Properties > Unlock.**

Since we live in a world, where On-Premises AD has no out-of-box utility to adequately notify the user of his soon to expire password, there is a natural need to come up with something that will do that.
This time, I humbly present you this simple (and yet effective) PS script that sends email to AD users who's password is about to expire.
It can be run manually or headless through the Task Scheduler.
However, this time you will need to manually set up the SMTP server, port, credentials, and the location from where the users will be taken in form of a simple DistinguishedName attribute.

As a nice-to-have, it logs separately every run into a C:\by3142\PasswordNotifier folder.
