module IB

  module Messages
  end

  require 'ib-ruby/messages/outgoing'
  require 'ib-ruby/messages/incoming'

  IncomingMessages = Messages::Incoming # Legacy alias
  OutgoingMessages = Messages::Outgoing # Legacy alias
end
