require 'spec_helper'

shared_examples_for 'Valid DB-backed Model' do

  context 'with DB backend', :db => true do
    after(:all) do
      #DatabaseCleaner.clean
    end

    it_behaves_like 'Model with associations'

    it 'is saved' do
      subject.save.should be_true
      @saved = subject
    end

    it 'does not set created and updated properties to SAVED model' do
      subject.created_at.should be_a Time
      subject.updated_at.should be_a Time
    end

    it 'saves a single model' do
      all_models = described_class.find(:all)
      all_models.should have_exactly(1).model
    end

    it 'loads back in the same valid state as saved' do
      model = described_class.find(:first)
      model.object_id.should_not == subject.object_id
      #model.valid?
      #p model.errors
      model.should be_valid
      model.should == subject
    end

    it 'and with the same properties' do
      model = described_class.find(:first)
      props.each do |name, value|
        model.send(name).should == value
      end
    end

    it 'updates timestamps when saving the model' do
      model = described_class.find(:first)
      model.created_at.usec.should_not == subject.created_at.utc.usec #be_a Time
      model.updated_at.usec.should_not == subject.updated_at.utc.usec #be_a Time
    end

    it 'is loads back with associations, if any' do
      if defined? associations
      end
    end

  end # DB
end

shared_examples_for 'Invalid DB-backed Model' do

  context 'with DB backend', :db => true do
    after(:all) { DatabaseCleaner.clean }

    it_behaves_like 'Model with associations'

    it 'is not saved' do
      subject.save.should be_false
    end

    it 'is not loaded' do
      models = described_class.find(:all)
      models.should have_exactly(0).model
    end
  end # DB
end

shared_examples_for 'Model with associations' do
  it 'works with associations, if any' do
    if defined? associations
      associations.each do |assoc, items|
        proxy = subject.association(assoc).reflection
        #pp proxy

        owner_name = described_class.to_s.demodulize.tableize.singularize
        [items].flatten.each do |item|
          if proxy.collection?
            association = subject.send("#{assoc}")
            association << item

            p 'collection'
            association.should include item
            #p association.first.send(owner_name)
            #.should include item
            #association.
            #association.size.should == items.size # Not for Order, +1 OrderState
          else
            subject.send "#{assoc}=", item
            association = subject.send("#{assoc}")
            p 'not a collection'
            association.should == item
          end
        end

      end
    end
  end
end
