require "spec_helper"

describe OrderStatesController do
  describe "routing" do

    it "routes to #index" do
      get("/order_states").should route_to("order_states#index")
    end

    it "routes to #new" do
      get("/order_states/new").should route_to("order_states#new")
    end

    it "routes to #show" do
      get("/order_states/1").should route_to("order_states#show", :id => "1")
    end

    it "routes to #edit" do
      get("/order_states/1/edit").should route_to("order_states#edit", :id => "1")
    end

    it "routes to #create" do
      post("/order_states").should route_to("order_states#create")
    end

    it "routes to #update" do
      put("/order_states/1").should route_to("order_states#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/order_states/1").should route_to("order_states#destroy", :id => "1")
    end

  end
end
