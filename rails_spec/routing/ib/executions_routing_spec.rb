require "spec_helper"

describe Ib::ExecutionsController, :type => :routing do
  describe "routing" do
    before(:each) { @routes = Ib::Engine.routes }

    it "routes to #index" do
      get("/executions").should route_to("ib/executions#index")
    end

    it "routes to #new" do
      get("/executions/new").should route_to("ib/executions#new")
    end

    it "routes to #show" do
      get("/executions/1").should route_to("ib/executions#show", :id => "1")
    end

    it "routes to #edit" do
      get("/executions/1/edit").should route_to("ib/executions#edit", :id => "1")
    end

    it "routes to #create" do
      post("/executions").should route_to("ib/executions#create")
    end

    it "routes to #update" do
      put("/executions/1").should route_to("ib/executions#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/executions/1").should route_to("ib/executions#destroy", :id => "1")
    end

  end
end
