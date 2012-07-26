require "spec_helper"

describe Ib::ContractsController, :type => :routing do
  describe "routing" do
    before(:each) { @routes = Ib::Engine.routes }

    it "routes to #index" do
      get("/contracts").should route_to("ib/contracts#index")
    end

    it "routes to #new" do
      get("/contracts/new").should route_to("ib/contracts#new")
    end

    it "routes to #show" do
      get("/contracts/1").should route_to("ib/contracts#show", :id => "1")
    end

    it "routes to #edit" do
      get("/contracts/1/edit").should route_to("ib/contracts#edit", :id => "1")
    end

    it "routes to #create" do
      post("/contracts").should route_to("ib/contracts#create")
    end

    it "routes to #update" do
      put("/contracts/1").should route_to("ib/contracts#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/contracts/1").should route_to("ib/contracts#destroy", :id => "1")
    end

  end
end
