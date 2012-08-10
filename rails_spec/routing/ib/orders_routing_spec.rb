require "spec_helper"

describe Ib::OrdersController, :type => :routing do
  describe "routing" do

    before(:each) { @routes = Ib::Engine.routes }

    it "routes to #index" do
      get("/orders").should route_to("ib/orders#index")
    end

    it "routes to #new" do
      get("/orders/new").should route_to("ib/orders#new")
    end

    it "routes to #show" do
      get("/orders/1").should route_to("ib/orders#show", :id => "1")
    end

    it "routes to #edit" do
      get("/orders/1/edit").should route_to("ib/orders#edit", :id => "1")
    end

    it "routes to #create" do
      post("/orders").should route_to("ib/orders#create")
    end

    it "routes to #update" do
      put("/orders/1").should route_to("ib/orders#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/orders/1").should route_to("ib/orders#destroy", :id => "1")
    end

  end
end
