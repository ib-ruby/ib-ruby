require "spec_helper"

describe Ib::ContractDetailsController, :type => :routing do
  describe "routing" do
    before(:each) { @routes = Ib::Engine.routes }

    it "routes to #index" do
      get("/contract_details").should route_to("ib/contract_details#index")
    end

    it "routes to #new" do
      get("/contract_details/new").should route_to("ib/contract_details#new")
    end

    it "routes to #show" do
      get("/contract_details/1").should route_to("ib/contract_details#show", :id => "1")
    end

    it "routes to #edit" do
      get("/contract_details/1/edit").should route_to("ib/contract_details#edit", :id => "1")
    end

    it "routes to #create" do
      post("/contract_details").should route_to("ib/contract_details#create")
    end

    it "routes to #update" do
      put("/contract_details/1").should route_to("ib/contract_details#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/contract_details/1").should route_to("ib/contract_details#destroy", :id => "1")
    end

  end
end
