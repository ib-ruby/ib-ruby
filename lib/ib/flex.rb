require 'net/http'
require 'net/https'
#require 'xmlsimple'
require 'ox'

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
  class Flex
    class << self
      attr_accessor :token, :uri

      # By default, uri is a well known FLEX Web Service URI
      def uri
        #@uri || 'https://www.interactivebrokers.com/Universal/servlet/FlexStatementService.SendRequest'
        @uri || 'https://gdcdyn.interactivebrokers.com/Universal/servlet/FlexStatementService.SendRequest'
      end
    end

    #  Create new Flex query with options:
    #    :token => 1111111111111111111111111111111111  # CHANGE to your actual token!
    #    :query_id => 11111                            # CHANGE to actual query id!
    #    :format => :xml (default) / :csv
    #    :verbose => true / false (default)
    def initialize opts
      @query_id = opts[:query_id]
      @token = opts[:token] || Flex.token
      @format = opts[:format] || :xml
      @verbose = !!opts[:verbose]
      yield self if block_given?
    end

    # Run a pre-defined Flex query against IB Flex Web Service
    # Returns a (parsed) report or raises FlexError in case of problems
    def run
      # Initiate FLEX request at a known FLEX Web Service URI
      resp = get_content Flex.uri, :t => @token, :q => @query_id, :v => 3
      error("#{resp['ErrorCode']}: #{resp['ErrorMessage']}", :flex) if resp['Status'] == 'Fail'

      reference_code = resp['ReferenceCode']
      report_uri = resp['Url']

      # Retrieve the FLEX report
      report = nil
      until report do
        report = get_content(report_uri, :t => @token, :q => reference_code, :v => 3,
                               :text_ok => @format != :xml)

          # If Status is specified, returned xml contains only error message, not actual report
          if report.is_a?(Hash) && report['Status'] =~ /Fail|Warn/
            error_code = report['ErrorCode'].to_i
            error_message = "#{error_code}: #{report['ErrorMessage']}"

            case error_code
            when 1001..1009, 1018, 1019, 1021
              # Report is just not ready yet, wait and retry
              puts error_message if @verbose
              report = nil
              sleep 1
            else # Fatal error
              error error_message, :flex
            end
          end
      end
      report
    end

    # Helper method to get (and parse XML) responses from IB Flex Web Service
    def get_content address, fields
      text_ok = fields.delete(:text_ok)
      resp = get address, fields
      if resp.content_type == 'text/xml'
        XmlSimple.xml_in(resp.body, :ForceArray => false)
      else
        error("Expected xml, got #{resp.content_type}", :flex) unless text_ok
        resp.body
      end
    end

    # Helper method to get raw responses from IB Flex Web Service
    def get address, fields
      uri = URI("#{address}?" + fields.map { |k, v| "#{k}=#{URI.encode(v.to_s)}" }.join('&'))

      server = Net::HTTP.new(uri.host, uri.port)
      server.use_ssl = (uri.scheme == 'https')
      server.verify_mode = OpenSSL::SSL::VERIFY_NONE if server.use_ssl? # Avoid OpenSSL failures

      resp = server.start do |http|
        req = Net::HTTP::Get.new(uri.request_uri)
        http.request(req)
      end
      error("URI responded with #{resp.code}", :flex) unless resp.code.to_i == 200
      resp
    end

  end
end
