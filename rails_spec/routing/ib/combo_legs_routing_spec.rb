require "spec_helper"

describe ComboLegsController do
  describe "routing" do

    it "routes to #index" do
      get("/combo_legs").should route_to("combo_legs#index")
    end

    it "routes to #new" do
      get("/combo_legs/new").should route_to("combo_legs#new")
    end

    it "routes to #show" do
      get("/combo_legs/1").should route_to("combo_legs#show", :id => "1")
    end

    it "routes to #edit" do
      get("/combo_legs/1/edit").should route_to("combo_legs#edit", :id => "1")
    end

    it "routes to #create" do
      post("/combo_legs").should route_to("combo_legs#create")
    end

    it "routes to #update" do
      put("/combo_legs/1").should route_to("combo_legs#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/combo_legs/1").should route_to("combo_legs#destroy", :id => "1")
    end

  end
end
