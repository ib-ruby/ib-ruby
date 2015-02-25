require 'ostruct'
require 'spec_helper'
 require 'message_helper'  # (logging)
describe IB::Alert do
    let( :alert_msg ) { OpenStruct.new  code: 234 , description: "This is a testmessage" , error_id: 567  }
  context 'initiate class' do
    it 'create a singleton' do
      IB::Alert.logger = mock_logger
      expect(IB::Alert).to be_a IB::Alert
    end
  end
  context "basics" do
    

    it 'generates a method' do
      IB::Alert.logger= mock_logger  #new unless IB::Alert.current.present?
#      ia =   IB::Alert.current
#      ias= ia.methods.size
      IB::Alert.alert_234 alert_msg 
#      expect( ia.method.size).to be > ias

    end
  end
#  context "defined resonse" do
#    def IB::Alert.alert_625 msg
#
#    end
#  end
end

