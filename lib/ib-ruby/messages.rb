module IB
  module Messages
  end
end

require 'ib-ruby/messages/outgoing'
require 'ib-ruby/messages/incoming'

module IB
  IncomingMessages = Messages::Incoming # Legacy alias
  OutgoingMessages = Messages::Outgoing # Legacy alias
end
