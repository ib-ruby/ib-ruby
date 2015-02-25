module IB
  class Alert
=begin
The Singleton IB::Alert handles any response to IB:Messages
=end
  
    # acts as prototype for any generated method 
    #require 'active_support'

    mattr_accessor :logger

      def self.method_missing( method_id, msg ) #, *args, &block )
	if msg.is_a?  IB::Messages::Incoming::Alert
	      logger.debug { msg.to_human }
	else
	      logger.error { "Argument to IB::Alert must be a IB::Messages::Incomming::Alert" }
	      logger.error { "The object: #{msg.inspect} " }
	end
      rescue NoMethodError
	unless logger.nil?
	logger.error { "The Argument is not a valid  IB::Messages:Incomming::Alert object"}
	logger.error { "The object: #{msg.inspect} " }
	else
	  puts "No Logging-Device specified"
	  puts "The object: #{msg.inspect} "
	end
      end



      class << self

	def ignore_alerts  *codes
	  codes.each do |n|
	    class_eval <<-EOD
	      def self.alert_#{n} msg
			# even the log_debug entry is suppressed 
		end              
	      EOD
	  end
	end
	def log_alert_in_info  *codes
	  codes.each do |n|
	    class_eval <<-EOD
	      def self.alert_#{n} msg
	      logger.info { msg.to_human }
		end              
	      EOD
	  end
	end
	def log_alert_in_warn  *codes
	  codes.each do |n|
	    class_eval <<-EOD
	      def self.alert_#{n} msg
	      logger.warn { msg.to_human }
		end              
	      EOD
	  end
	end

	def log_alert_in_error  *codes
	codes.each do |n|
	    class_eval <<-EOD
	      def self.alert_#{n} msg
		if msg.error_id.present? && msg.error_id > 0
		  logger.error {  msg.message + ' id:' + msg.error_id }
		else
		  logger.error {  msg.message   }
		end
	      end              
	      EOD
	  end
	end
      end

      ignore_alerts 200 , # is handled by IB::Contract.update_contract
		    2100, # API client has been unsubscribed from account data
		    399 # your order will not be placed at the exchange until

      log_alert_in_info    1102 #Connectivity between IB and Trader Workstation has been restored


      log_alert_in_error 320, 321, 323, 324, #ServerError
			  103, #duplicate order
			  201, #deleted object
			  326 #Unable connect as the client id is already in use

      log_alert_in_warn  354 #Requested market data is not subscribed
		    


  end
end
