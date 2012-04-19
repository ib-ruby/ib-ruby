require 'spec_helper'

def codes_and_values_for property
  Hash[IB::VALUES[property].map { |code, value| [[code, value], value] }]
end

shared_examples_for 'Model' do
  context 'instantiation without properties' do
    subject { described_class.new }

    it_behaves_like 'Model instantiated empty'
  end

  context 'instantiation with properties' do
    subject { described_class.new props }

    it_behaves_like 'Model instantiated with properties'


    it 'has correct human-readeable format' do
      subject.to_human.should == human
    end
  end
end

shared_examples_for 'Self-equal Model' do
  subject { described_class.new(props) }

  it 'is self-equal ' do
    should == subject
  end

  it 'is equal to Model with the same properties' do
    should == described_class.new(props)
  end
end

shared_examples_for 'Model instantiated empty' do
  it { should_not be_nil }

  it 'sets all properties to defaults' do
    defined?(defaults) && defaults.each do |name, value|
      #p name, value
      case value
        when Module, Class
          subject.send(name).should be_a value
        else
          subject.send(name).should == value
      end
    end
  end

  it_behaves_like 'Model properties'
  it_behaves_like 'Invalid Model'
end

shared_examples_for 'Model instantiated with properties' do
  it 'auto-assigns all properties given to initializer' do
    props.each do |name, value|
      subject.send(name).should == value
    end
  end

  it_behaves_like 'Model properties'
  it_behaves_like 'Valid Model'
end

shared_examples_for 'Model properties' do

  it 'allows setting properties' do
    expect {
      props.each do |name, value|
        subject.send("#{name}=", value)
        subject.send(name).should == value
      end
    }.to_not raise_error
  end

  it 'sets values to properties as directed by its setters' do
    defined?(assigns) && assigns.each do |props, cases|
      #p props, cases

      # For each given property ...
      [props].flatten.each do |prop|

        # For all test cases given as an Array [res1, res2] or Hash {val => res} ...
        (cases.is_a?(Array) ? cases.map { |e| [e, e] } : cases).each do |values, result|

          # For all values in this test case ...
          [values].flatten.each do |value|

            # Assigning this value to property results in ...
            case result
              when Exception # ... Exception
                expect { subject.send "#{prop}=", value }.
                    to raise_error result

              when Regexp # ... Non-exceptional error, making model invalid
                expect { subject.send "#{prop}=", value }.to_not raise_error
                subject.should be_invalid

                #pp subject.errors.messages
                #p value, result

                subject.errors.messages[prop].should_not be_nil
                msg = subject.errors.messages[prop].find { |msg| msg =~ result }
                msg.should =~ result

              else # ... correct uniform assignment to result

                was_valid = subject.valid?
                expect { subject.send "#{prop}=", value }.to_not raise_error
                subject.send("#{prop}").should == result

                was_valid && (subject.should be_valid) # assignment keeps validity
            end
          end
        end
      end
    end
  end

end

shared_examples_for 'Valid Model' do

  it 'validates' do
    subject.should be_valid
    subject.errors.should be_empty
  end

  context 'with DB backend', :db => true do
    after(:all) do
      #DatabaseCleaner.clean
    end

    it 'is saved' do
      subject.save.should be_true
      @saved = subject
    end

    it 'does not set created and updated properties to SAVED model' do
      subject.created_at.should be_nil
      subject.updated_at.should be_nil
    end

    it 'saves a single model' do
      all_models = described_class.find(:all)
      all_models.should have_exactly(1).model
    end

    it 'loads back in the same valid state as saved' do
      model = described_class.find(:first)
      model.object_id.should_not == subject.object_id
      model.should be_valid
      model.should == subject
    end

    it 'and with the same properties' do
      model = described_class.find(:first)
      props.each do |name, value|
        model.send(name).should == value
      end
    end

    it 'adds created and updated properties to loaded model' do
      model = described_class.find(:first)
      model.created_at.should be_a Time
      model.updated_at.should be_a Time
    end

    it 'is saved with associations, if any' do
      if defined? association
        p association
      end
    end

  end # DB
end

shared_examples_for 'Invalid Model' do
  it 'does not validate' do
    subject.should_not be_valid
    subject.should be_invalid
    subject.errors.should_not be_empty
    subject.errors.messages.should == errors if defined? errors
  end

  context 'with DB backend', :db => true do
    after(:all) do
      #DatabaseCleaner.clean
    end

    it 'is not saved' do
      subject.save.should be_false
    end

    it 'is not loaded' do
      models = described_class.find(:all)
      models.should have_exactly(0).model
    end
  end # DB
end

shared_examples_for 'Contract' do
  it 'summary points to itself (ContractDetails artifact' do
    subject.summary.should == subject
  end

  it 'becomes invalid if assigned wrong :sec_type property' do
    subject.sec_type = 'FOO'
    subject.should be_invalid
    subject.errors.messages[:sec_type].should include "should be valid security type"
  end

  it 'becomes invalid if assigned wrong :right property' do
    subject.right = 'BAR'
    subject.should be_invalid
    subject.errors.messages[:right].should include "should be put, call or none"
  end

  it 'becomes invalid if assigned wrong :expiry property' do
    subject.expiry = 'BAR'
    subject.should be_invalid
    subject.errors.messages[:expiry].should include "should be YYYYMM or YYYYMMDD"
  end

  it 'becomes invalid if primary_exchange is set to SMART' do
    subject.primary_exchange = 'SMART'
    subject.should be_invalid
    subject.errors.messages[:primary_exchange].should include "should not be SMART"
  end

end
