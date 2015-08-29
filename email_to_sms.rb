require 'gmail'
require 'twilio-ruby'
require 'yaml'

class EmailToSms
  
  MAX_EMAIL_TO_PROCESS=20
  SLEEP_AFTER_CHECK_CYCLE=30
  
  def initialize(config_file)
    @email_config = YAML.load_file(config_file)

    @hi_prio_from = Regexp.union(@email_config['hi_prio_froms']) || raise("Missing configuration for hi_prio_froms")

    #Configuration of Gmail
    @gmail_username = @email_config['gmail_username'] || raise("Missing configuration for gmail_username")
    @gmail_password = @email_config['gmail_password'] || raise("Missing configuration for gmail_password")

    #Configuration of Twilio
    @default_to = @email_config['sms_to'] || raise("Missing configuration for sms_to")
    @default_from = @email_config['sms_from'] || raise("Missing configuration for sms_from")
    @twilio_sid = @email_config['twilio_sid'] || raise("Missing configuration for twilio_sid")
    @twilio_token = @email_config['twilio_token'] || raise("Missing configuration for twilio_token")

    # set up a client to talk to the Twilio REST API
    @twilio = Twilio::REST::Client.new @twilio_sid, @twilio_token
  end
  
  # execute the class a service
  def server
    while (true) do
      main_loop
      
      puts "Sleeping #{SLEEP_AFTER_CHECK_CYCLE} seconds"
      sleep SLEEP_AFTER_CHECK_CYCLE
    end
  end
  
  private
  
  # Connect to gmail, check for important messages, send an SMS with the subject of the important ones
  def main_loop
    Gmail.connect!(@gmail_username, @gmail_password) do |gmail|
      gmail.inbox.find(:unread)[0..MAX_EMAIL_TO_PROCESS].each do |email| 
        process_email(email)
      end
    end
  end
  
  # Check if the email matches, if so, send an SMS
  def process_email(email)
    from = "#{email.from[0].mailbox}@#{email.from[0].host}"

    puts "Processing [from=#{from}] [who=#{email.from[0].name}] [subject=#{email.subject}]"

    if is_a_match?(from)
      send_sms(email)
      email.read! #we mark the email as read, so it will be skipped thereafter
    end
  end
  
  # Sends an SMS with the subject
  def send_sms(email)
    puts "Match! Sending SMS to [#{@default_to}] with body [#{email.subject}]"
    
    @twilio.messages.create(
      from: @default_from,
      to: @default_to,
      body: "#{email.from[0].name}: #{email.subject}"
    )
  end
  
  def is_a_match?(from)
    @hi_prio_from.match(from)
  end
  
end

config_file = ARGV[0] #first parameter is the configuration file
if config_file.nil? || config_file == ''
  puts "Usage: ruby email_to_sms.rb <config_file>"
  exit
end

EmailToSms.new(config_file).server