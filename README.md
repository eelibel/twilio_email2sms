This is a side project to play with Twilio APIs.

I wanted to route to my cell phone important emails that were coming to my GMail address.
This simple script will be listening to all incoming emails of my account (every 30 seconds). If any of the emails' from is one of the addresses I have marked as "high priority", the script will send me a text message notifying me of the new email and subject.

To use it:

* Download the project
* Run `bundle install`
* Change the configuration of email_to_sms.yml, by adding your email/password and twilio credentials
* Add in the email_to_sms.yml the list of froms you want to consider high priority
* Run it as `ruby email_to_sms.rb ./email_to_sms.yml`

Enjoy!