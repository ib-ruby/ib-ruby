require "spec_helper"

describe Ib::UnderlyingsController, :type => :routing do
  describe "routing" do
    # Mounted Engine routes do not work properly in specs, need to hack @routes directly
    # before(:all) { pp (IB::Engine.routes.routes.methods - Object.methods.sort) }
    # before(:all) { pp 1111111111111; IB::Engine.routes.routes.each {|r| pp(r.methods - Object.methods.sort)} }
    before(:all) { Ib::Engine.routes.routes.each {|r| pp [r.verb, r.defaults] } }
    before(:each) { @routes = Ib::Engine.routes }

    it "routes / to the underlyings index" do
      { :get => "/" }.should route_to(:controller => "ib/underlyings", :action => "index")
    end

    it "routes to #index" do
      get("/underlyings").should route_to("ib/underlyings#index")
    end

    it "routes to #new" do
      get("/underlyings/new").should route_to("ib/underlyings#new")
    end

    it "routes to #show" do
      get("/underlyings/1").should route_to("ib/underlyings#show", :id => "1")
    end

    it "routes to #edit" do
      get("/underlyings/1/edit").should route_to("ib/underlyings#edit", :id => "1")
    end

    it "routes to #create" do
      post("/underlyings").should route_to("ib/underlyings#create")
    end

    it "routes to #update" do
      put("/underlyings/1").should route_to("ib/underlyings#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/underlyings/1").should route_to("ib/underlyings#destroy", :id => "1")
    end

  end
end
