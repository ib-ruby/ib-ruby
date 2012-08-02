require "spec_helper"

describe Ib::BarsController, :type => :routing do
  describe "routing" do

    # Mounted Engine routes do not work properly in specs, need to hack @routes directly
    # before(:all) { pp (IB::Engine.routes.routes.methods - Object.methods.sort) }
    # before(:all) { pp 1111111111111; IB::Engine.routes.routes.each {|r| pp(r.methods - Object.methods.sort)} }
    before(:all) { Ib::Engine.routes.routes.each {|r| pp [r.verb, r.defaults] } }
    before(:each) { @routes = Ib::Engine.routes }

    it "routes to #index" do
      get("/bars").should route_to("ib/bars#index")
    end

    it "routes to #new" do
      get("/bars/new").should route_to("ib/bars#new")
    end

    it "routes to #show" do
      get("/bars/1").should route_to("ib/bars#show", :id => "1")
    end

    it "routes to #edit" do
      get("/bars/1/edit").should route_to("ib/bars#edit", :id => "1")
    end

    it "routes to #create" do
      post("/bars").should route_to("ib/bars#create")
    end

    it "routes to #update" do
      put("/bars/1").should route_to("ib/bars#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/bars/1").should route_to("ib/bars#destroy", :id => "1")
    end

  end
end
