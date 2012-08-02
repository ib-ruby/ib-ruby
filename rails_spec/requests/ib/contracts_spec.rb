require 'spec_helper'

describe "Contracts", :type => :request do
  describe "GET /contracts" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get contracts_path
      response.status.should be(200)
    end
  end
end
