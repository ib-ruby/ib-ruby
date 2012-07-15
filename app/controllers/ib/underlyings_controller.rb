require_dependency "ib/application_controller"

module Ib
  class UnderlyingsController < ApplicationController
    # GET /underlyings
    # GET /underlyings.json
    def index
      @underlyings = Underlying.all
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render :json => @underlyings }
      end
    end
  
    # GET /underlyings/1
    # GET /underlyings/1.json
    def show
      @underlying = Underlying.find(params[:id])
  
      respond_to do |format|
        format.html # show.html.erb
        format.json { render :json => @underlying }
      end
    end
  
    # GET /underlyings/new
    # GET /underlyings/new.json
    def new
      @underlying = Underlying.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render :json => @underlying }
      end
    end
  
    # GET /underlyings/1/edit
    def edit
      @underlying = Underlying.find(params[:id])
    end
  
    # POST /underlyings
    # POST /underlyings.json
    def create
      @underlying = Underlying.new(params[:underlying])
  
      respond_to do |format|
        if @underlying.save
          format.html { redirect_to @underlying, :notice => 'Underlying was successfully created.' }
          format.json { render :json => @underlying, :status => :created, :location => @underlying }
        else
          format.html { render :action => "new" }
          format.json { render :json => @underlying.errors, :status => :unprocessable_entity }
        end
      end
    end
  
    # PUT /underlyings/1
    # PUT /underlyings/1.json
    def update
      @underlying = Underlying.find(params[:id])
  
      respond_to do |format|
        if @underlying.update_attributes(params[:underlying])
          format.html { redirect_to @underlying, :notice => 'Underlying was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render :action => "edit" }
          format.json { render :json => @underlying.errors, :status => :unprocessable_entity }
        end
      end
    end
  
    # DELETE /underlyings/1
    # DELETE /underlyings/1.json
    def destroy
      @underlying = Underlying.find(params[:id])
      @underlying.destroy
  
      respond_to do |format|
        format.html { redirect_to underlyings_url }
        format.json { head :no_content }
      end
    end
  end
end
