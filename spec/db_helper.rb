require 'spec_helper'

shared_examples_for 'Valid DB-backed Model' do

  context 'with DB backend', :db => true do
    #after(:all) { DatabaseCleaner.clean }

    it_behaves_like 'Model with associations'

    it 'is saved' do
     expect( subject.save).to  be_truthy
      @saved = subject
    end

    it 'does not set created and updated properties to SAVED model' do
      expect( subject.created_at).to  be_a Time
#      subject.updated_at.should be_a Time   
    end

    it 'saves a single model' do
      all_models = described_class.find(:all)
      expect( all_models).to have_exactly(1).model
    end

    it 'loads back in the same valid state as saved' do
      model = described_class.find(:first)
      expect( model.object_id).not_to eq subject.object_id
      #model.valid?
      #p model.errors
      expect( model).to be_valid
      expect( model).to eq subject
    end

    it 'and with the same properties' do
      if init_with_props?
        model = described_class.find(:first)
        #p model.attributes
        #p model.content_attributes
        props.each do |name, value|
          expect( model.send(name)).to eq value
        end
      end
    end

    it 'updates timestamps when saving the model' do
      model = described_class.find(:first)
     expect( model.created_at.usec).not_to eq subject.created_at.utc.usec #be_a Time
     # model.updated_at.usec.should_not == subject.updated_at.utc.usec #be_a Time
    end

    it 'is loads back with associations, if any' do
      if defined? associations
      end
    end

  end # DB
end

shared_examples_for 'Invalid DB-backed Model' do

  context 'with DB backend', :db => true do
   # after(:all) { DatabaseCleaner.clean }

    it_behaves_like 'Model with associations'

    it 'is not saved' do
      expect( subject.save).to be_falsy
    end

    it 'is not loaded' do
      models = described_class.find(:all)
      expect( models).to have_exactly(0).model
    end
  end # DB
end

shared_examples_for 'Model with associations' do

  it 'works with associations, if any' do

    subject_name_plural = described_class.to_s.demodulize.tableize

    associations.each do |name, item_props|
      item = "IB::#{name.to_s.classify}".constantize.new item_props
      #item = const_get("IB::#{name.to_s.classify}").new item_props
      puts "Testing single association #{name}"
      expect( subject.association(name).reflection).not_to  be_collection

      # Assign item to association
      expect { subject.send "#{name}=", item }.to_not raise_error

      association = subject.send name #, :reload
      expect( association ).to eq item
      expect( association ).to be_new_record

      # Reverse association does not include subject
      reverse_association = association.send(subject_name_plural)
      expect( reverse_association).to be_empty

      # Now let's save subject
      if subject.valid?
        subject.save

        association = subject.send name
        expect( association ).not_to be_new_record

        # Reverse association now DOES include subject (if reloaded!)
        reverse_association = association.send(subject_name_plural, :reload)
        expect( reverse_association).to include subject
      end
    end
  end

  it 'works with associated collections, if any' do
    subject_name = described_class.to_s.demodulize.tableize.singularize

    collections.each do |name, items|
      puts "Testing associated collection #{name}"
      expect( subject.association(name).reflection).to be_collection

      [items].flatten.each do |item_props|
        item = "IB::#{name.to_s.classify}".constantize.new item_props
        #item = item_class.new item_props
        association = subject.send name #, :reload

        # Add item to collection
        expect { association << item }.to_not raise_error
        expect( association).to include item

        # Reverse association does NOT point to subject
        reverse_association = association.first.send(subject_name)
        #reverse_association.should be_nil # But not always!

        #association.size.should == items.size # Not for Order, +1 OrderState
      end

      # Now let's save subject
      if subject.valid?
        subject.save

        [items].flatten.each do |item_props|
          item = "IB::#{name.to_s.classify}".constantize.new item_props
          association = subject.send name #, :reload

          expect( association ).to include item

          # Reverse association DOES point to subject now
          reverse_association = association.first.send(subject_name)
          expect( reverse_association).to eq subject
        end
      end
    end
  end


end
