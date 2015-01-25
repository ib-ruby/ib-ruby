require 'message_helper'

describe IB::Messages::Incoming::AbstractMessage do

  describe '#resolve_message_classes' do

    it 'should be able to resolve classes' do
      m = IB::Messages::Incoming::AbstractMessage.resolve_message_classes(IB::Messages::Incoming::HistoricalData)
      m.length.should == 1
      m.should include(IB::Messages::Incoming::HistoricalData)
    end

    it 'should be able to resolve symbols' do
      m = IB::Messages::Incoming::AbstractMessage.resolve_message_classes(:Alert)
      m.length.should == 1
      m.should include(IB::Messages::Incoming::Alert)
    end

    it 'should be able to resolve regexes' do
      m = IB::Messages::Incoming::AbstractMessage.resolve_message_classes(/.+Data$/)
      m.length.should == 6
      m.should include(IB::Messages::Incoming::ScannerData)
    end

    it 'should be able to resolve arrays' do
      m = IB::Messages::Incoming::AbstractMessage.resolve_message_classes([:Alert, IB::Messages::Incoming::HistoricalData])
      m.length.should == 2
      m.should include(IB::Messages::Incoming::HistoricalData)
      m.should include(IB::Messages::Incoming::Alert)
    end

    
    it 'should raise when unable to resolve to a class' do
      expect { IB::Messages::Incoming::AbstractMessage.resolve_message_classes(:nonsense) }.to raise_error
    end

    it 'should be able to resolve complex combinations of parameters' do
      m = IB::Messages::Incoming::AbstractMessage.resolve_message_classes([:Alert, [IB::Messages::Incoming::HistoricalData, IB::Messages::Incoming::ScannerData], /::ContractData$/])
      m.length.should == 4
    end
    
  end
  
end
