require 'spec_helper'
require 'db_helper'

def codes_and_values_for property
  Hash[IB::VALUES[property].map { |code, value| [[code, value], value] }]
end

def numeric_assigns
  {1313 => 1313,
   [:foo, 'BAR'] => /is not a number/,
   nil => /is not a number/}
end

def numeric_or_nil_assigns
  numeric_assigns.merge(nil => nil)
end

def to_i_assigns
  {[1313, '1313'] => 1313,
   ['foo', 'BAR', nil, '', 0] => 0, } # Symbols NOT coerced! They DO have int equivalent
end

def float_assigns
  {13.13 => 13.13,
   13 => 13.0,
   nil => /is not a number/,
   [:foo, 'BAR'] => /is not a number/}
end

def to_f_assigns
  {13.13 => 13.13,
   13 => 13.0,
   [:foo, 'BAR', '', nil, 0] => 0.0}
end

def float_or_nil_assigns
  float_assigns.merge(nil => nil)
end

def boolean_assigns
  {[1, true, 't'] => true,
   [0, false, 'f'] => false}
end

def string_assigns
  {[:Bar, 'Bar'] => 'Bar',
   [:foo, 'foo'] => 'foo'}
end

def string_upcase_assigns
  {[:cboe, :Cboe, 'cboE', 'CBOE'] => 'CBOE',
   [:bar, 'Bar'] => 'BAR',
   [:foo, 'foo'] => 'FOO'}
end

def open_close_assigns
  {['SAME', 'same', 'S', 's', :same, 0, '0'] => :same,
   ['OPEN', 'open', 'O', 'o', :open, 1, '1'] => :open,
   ['CLOSE', 'close', 'C', 'c', :close, 2, '2'] => :close,
   ['UNKNOWN', 'unknown', 'U', 'u', :unknown, 3, '3'] => :unknown,
   [42, nil, 'Foo', :bar] => /should be same.open.close.unknown/}
end

def buy_sell_assigns
  {['BOT', 'BUY', 'Buy', 'buy', :BUY, :BOT, :Buy, :buy, 'B', :b] => :buy,
   ['SELL', 'SLD', 'Sel', 'sell', :SELL, :SLD, :Sell, :sell, 'S', :S] => :sell,
   [1, nil, 'ASK', :foo] => /should be buy.sell/
  }
end

def buy_sell_short_assigns
  buy_sell_assigns.merge(
      ['SSHORT', 'Short', 'short', :SHORT, :short, 'T', :T] => :short,
      ['SSHORTX', 'Shortextemt', 'shortx', :short_exempt, 'X', :X] => :short_exempt,
      [1, nil, 'ASK', :foo] => /should be buy.sell.short/)
end

def test_assigns cases, prop, name

  # For all test cases given as an Array [res1, res2] or Hash {val => res} ...
  (cases.is_a?(Array) ? cases.map { |e| [e, e] } : cases).each do |values, result|
    #p prop, cases

    # For all values in this test case ...
    [values].flatten.each do |value|
      #p prop, name, value, result

      # Assigning this value to a property results in ...
      case result
        when Exception # ... Exception
          expect { subject.send "#{prop}=", value }.
              to raise_error result

        when Regexp # ... Non-exceptional error, making model invalid
          expect { subject.send "#{prop}=", value }.to_not raise_error
          subject.valid? # just triggers validation

          #pp subject.errors.messages

          subject.errors.messages.should have_key name
          subject.should be_invalid
          msg = subject.errors.messages[name].find { |msg| msg =~ result }
          msg.should =~ result

        else # ... correct uniform assignment to result

          was_valid = subject.valid?
          expect { subject.send "#{prop}=", value }.to_not raise_error
          subject.send("#{prop}").should == result
          if was_valid
            # Assignment keeps validity
            subject.errors.messages.should_not have_key name
            subject.should be_valid
          end

          if name != prop # additional asserts for aliases

            # Assignment to alias changes property as well
            subject.send("#{name}").should == result

            # Unsetting alias unsets property as well
            subject.send "#{prop}=", nil # unset alias
            subject.send("#{prop}").should be_blank #== nil
            subject.send("#{name}").should be_blank #== nil

            # Assignment to original property changes alias as well
            subject.send "#{name}=", value
            subject.send("#{prop}").should == result
          end
      end
    end
  end
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
      case human
        when Regexp
          subject.to_human.should =~ human
        else
          subject.to_human.should == human
      end
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
    subject.default_attributes.each do |name, value|
      #p name, value
      case value
        when Time
          subject.send(name).should be_a Time
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
      #p subject, name, value
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
      # For each given property ...
      [props].flatten.each { |prop| test_assigns cases, prop, prop }

    end
  end

  it 'sets values to to aliased properties as well' do
    defined?(aliases) && aliases.each do |alinames, cases|
      name, aliases = *alinames
      # For each original property or alias...
      [name, aliases].flatten.each { |prop| test_assigns cases, prop, name }
    end
  end
end

shared_examples_for 'Valid Model' do

  it 'validates' do
    subject.should be_valid
    subject.errors.should be_empty
  end

  it_behaves_like 'Valid DB-backed Model'
end

shared_examples_for 'Invalid Model' do

  it 'does not validate' do
    subject.should_not be_valid
    subject.should be_invalid
    subject.errors.should_not be_empty
    subject.errors.messages.should == errors if defined? errors
  end

  it_behaves_like 'Invalid DB-backed Model'
end

shared_examples_for 'Contract' do
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
