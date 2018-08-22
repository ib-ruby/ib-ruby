require 'net/http'
require 'net/https'
#require 'xmlsimple'
require 'ox'
module Ox
	class Element
		def ox
			nodes.first
		end
	end
end

module IB

  # FLEX is a web-based service from IB that helps you to retrieve your activity,
  # trades and positions. It is working independently from TWS or Gateway, using your
  # internet connection directly. See /misc/flex for extended FLEX documentation.
  #
  # In order to use this service, activate it and configure your token first.
  # Your Token is located at Account Management->Reports->Delivery Settings->Flex Web Service.
  # You need to activate Flex Web Service and generate new token(s) there.
  # Your Flex Query Ids are in Account Management->Reports->Activity->Flex Queries.
  # Create new Flex query and make sure to set its output format to XML.
  #
  # IB::Flex object incapsulates a single pre-defined Flex query.
	#
	#Details: 
	#
	# https://www.interactivebrokers.com/en/software/am/am/reports/flex_web_service_version_3.htm
	#
	# Error Codes
	# https://www.interactivebrokers.com/en/software/am/am/reports/version_3_error_codes.htm
  class Flex

		mattr_accessor :token, :uri
    #  Create new Flex query with options:
    #    :token => 1111111111111111111111111111111111  # CHANGE to your actual token!
    #    :query_id => 11111                            # CHANGE to actual query id!
    #    :format => :xml (default) / :csv
    #    :verbose => true / false (default)
		#    :return_hash => true / false (default)
    def initialize query_id: nil ,  # must be specified
									 token: nil ,	# must be specified once
									 format: :xml,# or :csv
									 verbose:  false,
									 return_hash: false	

      # By default, uri is a well known FLEX Web Service URI
			self.uri =
				'https://gdcdyn.interactivebrokers.com/Universal/servlet/FlexStatementService.SendRequest'

			# convert parameters into instance-variables and assign them
			method(__method__).parameters.each do |type, k|
				next unless type == :key
				case k
				when :token
					self.token = token unless token.nil?
				else
					v = eval(k.to_s)
					instance_variable_set("@#{k}", v) unless v.nil?
				end
			end

			error "Token not set", :flex if Flex.token.nil?
			error "query_id not set", :flex if @query_id.nil?
			yield self if block_given?
		end

    # Run a pre-defined Flex query against IB Flex Web Service
    # Returns a (parsed) report or raises FlexError in case of problems
    def run
      # Initiate FLEX request at a known FLEX Web Service URI
			# get_content returns an Ox-Element-Object
			# Nodes > FlexStatementResponse and
			#			  > if Status is other then 'suscess'  ErrorCode and ErrorMessage
			#			  > otherwise Uri and  ReferenceCode

      statement = get_content( Flex.uri, :t => Flex.token, :q => @query_id, :v => 3)
			if @verbose
				puts "the Statement returned by the request of the query"	
				puts Ox.load(Ox.dump( statement), mode: :hash)  
			end
			error("Flex Query is invalid", :flex )  unless statement.value == 'FlexStatementResponse'
			error("#{statement.ErrorCode.ox.to_i}: #{statement.ErrorMessage.ox}", :flex) if statement.Status.ox != 'Success'
			#
      # Retrieve the FLEX report
      report = nil
      until report do
        sleep 5  # wait for the report to be prepared 
        report = get_content(statement.Url.ox,:t => Flex.token, :q => statement.ReferenceCode.ox, :v => 3,
                               :text_ok => @format != :xml)

          # If Status is specified, returned xml contains only error message, not actual report
          if report.nodes.include?('Status') && report.Status.ox =~ /Fail|Warn/
            error_code = report.ErrorCode.ox.to_i
            error_message = "#{error_code}: #{report.ErrorMessage.ox}"

            case error_code
            when 1001..1009, 1018, 1019, 1021
              # Report is just not ready yet, wait and retry
              puts error_message if @verbose
              report = nil
            else # Fatal error
              error error_message, :flex
            end
          end
      end
      @return_hash ? Ox.load( Ox.dump(report),  mode: :hash)  : report  # return hash or the Ox-Element
    end

    # Helper method to get (and parse XML) responses from IB Flex Web Service
    def get_content address, fields
		  get = -> ( the_uri ) do
				server = Net::HTTP.new(the_uri.host, the_uri.port)
				server.use_ssl =  true
				server.verify_mode = OpenSSL::SSL::VERIFY_NONE if server.use_ssl? # Avoid OpenSSL failures
				server.start{ |http| http.request( Net::HTTP::Get.new(the_uri.request_uri) ) }
			end
		
      text_ok = fields.delete(:text_ok)
      the_uri = URI("#{address}?" + fields.map { |k, v| "#{k}=#{URI.encode(v.to_s)}" }.join('&'))
			response = get[ the_uri ] 

      error("URI responded with #{response.code}", :flex) unless response.code.to_i == 200
			if text_ok
				response.body
			else
				Ox.parse response.body
			end
    end

    # Helper method to get the body of response from IB Flex Web Service
   # def get address, fields
   #   uri = URI("#{address}?" + fields.map { |k, v| "#{k}=#{URI.encode(v.to_s)}" }.join('&'))
	 # 	puts "URI #{uri}"
   #   server = Net::HTTP.new(uri.host, uri.port)
   #   server.use_ssl = (uri.scheme == 'https')
   #   server.verify_mode = OpenSSL::SSL::VERIFY_NONE if server.use_ssl? # Avoid OpenSSL failures

   #   resp = server.start do |http|
   #     req = Net::HTTP::Get.new(uri.request_uri)
   #     http.request(req)
   #   end
   #   error("URI responded with #{resp.code}", :flex) unless resp.code.to_i == 200
	 # 	
   #   resp.body
   # end

  end
end
