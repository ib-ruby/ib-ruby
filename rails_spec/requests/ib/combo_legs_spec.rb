require 'spec_helper'

describe "ComboLegs", :type => :request do
  describe "GET /combo_legs" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get combo_legs_path
      response.status.should be(200)
    end
  end
end
