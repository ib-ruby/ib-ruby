require "spec_helper"

describe ExecutionsController do
  describe "routing" do

    it "routes to #index" do
      get("/executions").should route_to("executions#index")
    end

    it "routes to #new" do
      get("/executions/new").should route_to("executions#new")
    end

    it "routes to #show" do
      get("/executions/1").should route_to("executions#show", :id => "1")
    end

    it "routes to #edit" do
      get("/executions/1/edit").should route_to("executions#edit", :id => "1")
    end

    it "routes to #create" do
      post("/executions").should route_to("executions#create")
    end

    it "routes to #update" do
      put("/executions/1").should route_to("executions#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/executions/1").should route_to("executions#destroy", :id => "1")
    end

  end
end
