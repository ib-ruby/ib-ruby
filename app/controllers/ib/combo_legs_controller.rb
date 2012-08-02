require_dependency "ib/application_controller"

module Ib
  class ComboLegsController < ApplicationController
    # GET /combo_legs
    # GET /combo_legs.json
    def index
      @combo_legs = ComboLeg.all
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render :json => @combo_legs }
      end
    end
  
    # GET /combo_legs/1
    # GET /combo_legs/1.json
    def show
      @combo_leg = ComboLeg.find(params[:id])
  
      respond_to do |format|
        format.html # show.html.erb
        format.json { render :json => @combo_leg }
      end
    end
  
    # GET /combo_legs/new
    # GET /combo_legs/new.json
    def new
      @combo_leg = ComboLeg.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render :json => @combo_leg }
      end
    end
  
    # GET /combo_legs/1/edit
    def edit
      @combo_leg = ComboLeg.find(params[:id])
    end
  
    # POST /combo_legs
    # POST /combo_legs.json
    def create
      @combo_leg = ComboLeg.new(params[:combo_leg])
  
      respond_to do |format|
        if @combo_leg.save
          format.html { redirect_to @combo_leg, :notice => 'Combo leg was successfully created.' }
          format.json { render :json => @combo_leg, :status => :created, :location => @combo_leg }
        else
          format.html { render :action => "new" }
          format.json { render :json => @combo_leg.errors, :status => :unprocessable_entity }
        end
      end
    end
  
    # PUT /combo_legs/1
    # PUT /combo_legs/1.json
    def update
      @combo_leg = ComboLeg.find(params[:id])
  
      respond_to do |format|
        if @combo_leg.update_attributes(params[:combo_leg])
          format.html { redirect_to @combo_leg, :notice => 'Combo leg was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render :action => "edit" }
          format.json { render :json => @combo_leg.errors, :status => :unprocessable_entity }
        end
      end
    end
  
    # DELETE /combo_legs/1
    # DELETE /combo_legs/1.json
    def destroy
      @combo_leg = ComboLeg.find(params[:id])
      @combo_leg.destroy
  
      respond_to do |format|
        format.html { redirect_to combo_legs_url }
        format.json { head :no_content }
      end
    end
  end
end
