require 'spec_helper'

shared_examples_for 'Valid DB-backed Model' do

  context 'with DB backend', :db => true do
    after(:all) { DatabaseCleaner.clean }

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
      #p model.attributes
      #p model.content_attributes
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

      subject_name_plural = described_class.to_s.demodulize.tableize

      associations.each do |name, item|
        puts "Testing single association #{name}"
        subject.association(name).reflection.should_not be_collection

        # Assign item to association
        expect { subject.send "#{name}=", item }.to_not raise_error

        association = subject.send name #, :reload
        association.should == item
        association.should be_new_record

        # Reverse association does not include subject
        reverse_association = association.send(subject_name_plural)
        reverse_association.should be_empty

        # Now let's save subject
        if subject.valid?
          subject.save

          association = subject.send name
          association.should_not be_new_record

          # Reverse association now DOES include subject (if reloaded!)
          reverse_association = association.send(subject_name_plural, :reload)
          reverse_association.should include subject
        end
      end
    end
  end

  it 'works with associated collections, if any' do
    if defined? collections

      subject_name = described_class.to_s.demodulize.tableize.singularize

      collections.each do |name, items|
        puts "Testing associated collection #{name}"
        subject.association(name).reflection.should be_collection

        [items].flatten.each do |item|
          association = subject.send name #, :reload

          # Add item to collection
          expect { association << item }.to_not raise_error
          association.should include item

          # Reverse association does NOT point to subject
          reverse_association = association.first.send(subject_name)
          #reverse_association.should be_nil # But not always!

          #association.size.should == items.size # Not for Order, +1 OrderState
        end

        # Now let's save subject
        if subject.valid?
          subject.save

          [items].flatten.each do |item|
            association = subject.send name #, :reload

            association.should include item

            # Reverse association DOES point to subject now
            reverse_association = association.first.send(subject_name)
            reverse_association.should == subject
          end
        end

      end
    end
  end
end
