require 'spec_helper'

shared_examples_for 'Model' do
  context 'instantiation without properties' do
    subject { described_class.new }

    it_behaves_like 'Model instantiated empty'
  end

  context 'instantiation with properties' do
    subject { described_class.new props }

    it_behaves_like 'Model instantiated with properties'
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
      case value
        when Module
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
      subject.send(name).should == (values[name].nil? ? value : values[name])
    end
  end

  it_behaves_like 'Model properties'
  it_behaves_like 'Valid Model'
end

shared_examples_for 'Model properties' do
  context 'essential properties are still set, even if not given explicitely' do
    its(:created_at) { should be_a Time }
  end

  it 'allows setting properties' do
    expect {
      props.each do |name, value|
        subject.send("#{name}=", value)
        subject.send(name).should == (values[name].nil? ? value : values[name])
      end
    }.to_not raise_error
  end

  it 'sets values to properties as directed by its setters' do
    defined?(assigns) && assigns.each do |props, cases|
      [props].flatten.each do |prop|
        (cases.is_a?(Array) ? cases.map { |e| [e, e] } : cases).
            each do |values, result|
          [values].flatten.each do |value|
            expect {
              subject.send "#{prop}=", value
            }.to_not raise_error
            subject.send("#{prop}").should == result
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
    end

    it 'is loaded just right' do
      models = described_class.find(:all)
      model = models.first
      #pp model
      models.should have_exactly(1).model
      model.should == subject
      model.should be_valid
      props.each do |name, value|
        model.send(name).should == (values[name].nil? ? value : values[name])
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
