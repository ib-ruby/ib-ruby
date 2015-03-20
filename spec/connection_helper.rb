

shared_examples_for 'Connected Connection' do
  
 it_behaves_like 'Connected Connection without receiver'

  it 'keeps received messages in Hash by default' do
	  expect( subject.received).to be_a Hash
	  expect( subject.received[:Alert]).not_to be_empty
	  expect( subject.received[:Alert]).to have_at_least(1).message
	  ## The test for an Item in the  NextValidID-Hash fails surprisingly
	  expect( subject.received[:NextValidId]).not_to be_empty
	  expect( subject.received[:NextValidId]).to have_exactly(1).message
#	  connection.close
  end
end

shared_examples_for 'Connected Connection without receiver' do

  it { is_expected.not_to  be_nil }
  it { is_expected.to  be_connected }
  its(:subscribers) { is_expected.to have_at_least(1).item } # :NextValidId and empty Hashes
  its(:received){ is_expected.to be_a Hash }
#  its(:next_local_id) { is_expected.to be_a Fixnum } # Not before :NextValidId arrives
end

