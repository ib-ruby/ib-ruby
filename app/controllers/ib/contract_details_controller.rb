require_dependency "ib/application_controller"

module Ib
  class ContractDetailsController < ApplicationController
    # GET /contract_details
    # GET /contract_details.json
    def index
      @contract_details = ContractDetail.all
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render :json => @contract_details }
      end
    end
  
    # GET /contract_details/1
    # GET /contract_details/1.json
    def show
      @contract_detail = ContractDetail.find(params[:id])
  
      respond_to do |format|
        format.html # show.html.erb
        format.json { render :json => @contract_detail }
      end
    end
  
    # GET /contract_details/new
    # GET /contract_details/new.json
    def new
      @contract_detail = ContractDetail.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render :json => @contract_detail }
      end
    end
  
    # GET /contract_details/1/edit
    def edit
      @contract_detail = ContractDetail.find(params[:id])
    end
  
    # POST /contract_details
    # POST /contract_details.json
    def create
      @contract_detail = ContractDetail.new(params[:contract_detail])
  
      respond_to do |format|
        if @contract_detail.save
          format.html { redirect_to @contract_detail, :notice => 'Contract detail was successfully created.' }
          format.json { render :json => @contract_detail, :status => :created, :location => @contract_detail }
        else
          format.html { render :action => "new" }
          format.json { render :json => @contract_detail.errors, :status => :unprocessable_entity }
        end
      end
    end
  
    # PUT /contract_details/1
    # PUT /contract_details/1.json
    def update
      @contract_detail = ContractDetail.find(params[:id])
  
      respond_to do |format|
        if @contract_detail.update_attributes(params[:contract_detail])
          format.html { redirect_to @contract_detail, :notice => 'Contract detail was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render :action => "edit" }
          format.json { render :json => @contract_detail.errors, :status => :unprocessable_entity }
        end
      end
    end
  
    # DELETE /contract_details/1
    # DELETE /contract_details/1.json
    def destroy
      @contract_detail = ContractDetail.find(params[:id])
      @contract_detail.destroy
  
      respond_to do |format|
        format.html { redirect_to contract_details_url }
        format.json { head :no_content }
      end
    end
  end
end
