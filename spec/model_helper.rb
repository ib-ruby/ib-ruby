require 'spec_helper'
require 'db_helper'

[:props, :aliases, :errors, :assigns, :human, :associations, :collections].each do |aspect|
  eval "def #{aspect}
          (metadata[:#{aspect}] rescue example.metadata[:#{aspect}]) || {}
        end"
end

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

    # For all values in this test case ...
    [values].flatten.each do |value|
      #p prop, name, value, result

      # Assigning this value to a property results in ...
      case result
      when Exception # ... Exception

        it "#{prop} = #{value.inspect} #=> raises #{result}" do
          expect { subject.send "#{prop}=", value }.
            to raise_error result
        end

      when Regexp # ... Non-exceptional error, making model invalid

        it "#{prop} = #{value.inspect} #=> error #{result.to_s}" do

          expect { subject.send "#{prop}=", value }.to_not raise_error

          subject.valid? # just triggers validation
          #pp subject.errors.messages

          subject.errors.messages.should have_key name
          subject.should be_invalid
          msg = subject.errors.messages[name].find { |msg| msg =~ result }
          msg.should =~ result
        end

      else # ... correct uniform assignment to result

        it "#{prop} = #{value.inspect} #=> #{result.inspect}" do

          was_valid = subject.valid?
          expect { subject.send "#{prop}=", value }.to_not raise_error
          subject.send("#{prop}").should == result
          if was_valid
            # Assignment keeps validity
            subject.errors.messages.should_not have_key name
            subject.should be_valid
          end
        end

        if name != prop # additional asserts for aliases

          it "#{prop} alias assignment changes #{name} property, and vice versa" do
            # Assignment to alias changes property as well
            subject.send "#{prop}=", value
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
end

RSpec.shared_examples_for 'Model with valid defaults' do
  context 'instantiation without properties' , focus: true do
    subject { described_class.new }
    let(:init_with_props?) { false }

    it_behaves_like 'Model properties'
    it_behaves_like 'Valid Model'
  end

  context 'instantiation with properties' do
    subject { described_class.new props }

    it_behaves_like 'Model instantiated with properties'
  end
end

RSpec.shared_examples_for 'Model with invalid defaults' do
  context 'instantiation without properties' do
    subject { described_class.new }

    it_behaves_like 'Model instantiated empty'
  end

  context 'instantiation with properties' do
    subject { described_class.new props }

    it_behaves_like 'Model instantiated with properties'
  end
end

RSpec.shared_examples_for 'Self-equal Model' do
  subject { described_class.new props }

  it 'is self-equal ' do
    should == subject
  end

  it 'is equal to Model with the same properties' do
    should == described_class.new(props)
  end
end

RSpec.shared_examples_for 'Model instantiated empty' do
  let(:init_with_props?) { false }
  it { should_not be_nil }

  it 'sets all properties to defaults' do
    subject.default_attributes.each do |name, value|
      # p name, subject.send(name), value
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

RSpec.shared_examples_for 'Model instantiated with properties' do
  let(:init_with_props?) { true }

  it 'auto-assigns all properties given to initializer' do
    # p subject
    props.each do |name, value|
      # p name, subject.send(name), value
      subject.send(name).should == value
    end
  end

  it 'has correct human-readeable format' do
    case human
    when Regexp
      subject.to_human.should =~ human
    else
      subject.to_human.should == human
    end
  end

  it_behaves_like 'Model properties'
  it_behaves_like 'Valid Model'
end

RSpec.shared_examples_for 'Model properties' do

  it 'leaves order_id alone, no aliasing' do
    if subject.respond_to?(:order_id)
      subject.order_id.should be_nil
      if subject.respond_to?(:local_id=)
        subject.local_id = 1313
        subject.order_id.should be_nil
        subject.order_id = 2222
        subject.local_id.should == 1313
      end
    end
  end

  it 'allows setting properties' do
    expect {
      props.each do |name, value|
        subject.send("#{name}=", value)
        subject.send(name).should == value
      end
    }.to_not raise_error
  end

  props.each do |name, value|
    it "#{name} = #{value.inspect} #=> does not raise" do
      expect {
        subject.send("#{name}=", value)
        subject.send(name).should == value
      }.to_not raise_error
    end
  end

  assigns.each do |props, cases|
    [props].flatten.each do |prop|
      # For each given property ...
      test_assigns cases, prop, prop
    end
  end

  aliases.each do |alinames, cases|
    name, aliases = *alinames
    # For each original property or alias...
    [name, aliases].flatten.each do |prop|
      test_assigns cases, prop, name
    end
  end

end

RSpec.shared_examples_for 'Valid Model' do

  it 'validates' do
    subject.should be_valid
    subject.errors.should be_empty
  end

  it_behaves_like 'Valid DB-backed Model'
end

RSpec.shared_examples_for 'Invalid Model' do

  it 'does not validate' do
    subject.should_not be_valid
    subject.should be_invalid
    subject.errors.should_not be_empty
    subject.errors.messages.should == errors
  end

  it_behaves_like 'Invalid DB-backed Model'
end

RSpec.shared_examples_for 'Contract' do
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
