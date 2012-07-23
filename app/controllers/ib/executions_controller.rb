require_dependency "ib/application_controller"

module Ib
  class ExecutionsController < ApplicationController
    # GET /executions
    # GET /executions.json
    def index
      @executions = Execution.all
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render :json => @executions }
      end
    end
  
    # GET /executions/1
    # GET /executions/1.json
    def show
      @execution = Execution.find(params[:id])
  
      respond_to do |format|
        format.html # show.html.erb
        format.json { render :json => @execution }
      end
    end
  
    # GET /executions/new
    # GET /executions/new.json
    def new
      @execution = Execution.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render :json => @execution }
      end
    end
  
    # GET /executions/1/edit
    def edit
      @execution = Execution.find(params[:id])
    end
  
    # POST /executions
    # POST /executions.json
    def create
      @execution = Execution.new(params[:execution])
  
      respond_to do |format|
        if @execution.save
          format.html { redirect_to @execution, :notice => 'Execution was successfully created.' }
          format.json { render :json => @execution, :status => :created, :location => @execution }
        else
          format.html { render :action => "new" }
          format.json { render :json => @execution.errors, :status => :unprocessable_entity }
        end
      end
    end
  
    # PUT /executions/1
    # PUT /executions/1.json
    def update
      @execution = Execution.find(params[:id])
  
      respond_to do |format|
        if @execution.update_attributes(params[:execution])
          format.html { redirect_to @execution, :notice => 'Execution was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render :action => "edit" }
          format.json { render :json => @execution.errors, :status => :unprocessable_entity }
        end
      end
    end
  
    # DELETE /executions/1
    # DELETE /executions/1.json
    def destroy
      @execution = Execution.find(params[:id])
      @execution.destroy
  
      respond_to do |format|
        format.html { redirect_to executions_url }
        format.json { head :no_content }
      end
    end
  end
end
