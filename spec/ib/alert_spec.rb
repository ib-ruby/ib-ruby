require 'ostruct'
require 'spec_helper'
 require 'message_helper'  # (logging)
describe IB::Alert do

    before(:all){ IB::Alert.logger = mock_logger }
    let( :alert_msg ) { OpenStruct.new  code: 234 , message: "This is a testmessage" , error_id: 567  }
  context "basics" do
    
#
    it 'generates a method' do
      IB::Alert.alert_234 alert_msg 
      # the code should appear in the log 
      expect( should_log /234/ ).to be_truthy
    end

    it 'ignores an alert' do

      IB::Alert.alert_200 "alert" 
      expect( should_not_log /200/ ).to be_truthy
  end

    it 'logs in error' do
      alert_msg
      alert_msg.code = 320
      IB::Alert.send "alert_#{alert_msg.code}", alert_msg
      expect( should_log /id: 567/ ).to be_truthy
    end

  end
end

