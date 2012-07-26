require 'spec_helper'

describe "ComboLegs" do
  describe "GET /ib_combo_legs" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get ib_combo_legs_path
      response.status.should be(200)
    end
  end
end
