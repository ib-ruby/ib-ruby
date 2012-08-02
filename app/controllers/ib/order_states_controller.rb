require_dependency "ib/application_controller"

module Ib
  class OrderStatesController < ApplicationController
    # GET /order_states
    # GET /order_states.json
    def index
      @order_states = OrderState.all
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render :json => @order_states }
      end
    end
  
    # GET /order_states/1
    # GET /order_states/1.json
    def show
      @order_state = OrderState.find(params[:id])
  
      respond_to do |format|
        format.html # show.html.erb
        format.json { render :json => @order_state }
      end
    end
  
    # GET /order_states/new
    # GET /order_states/new.json
    def new
      @order_state = OrderState.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render :json => @order_state }
      end
    end
  
    # GET /order_states/1/edit
    def edit
      @order_state = OrderState.find(params[:id])
    end
  
    # POST /order_states
    # POST /order_states.json
    def create
      @order_state = OrderState.new(params[:order_state])
  
      respond_to do |format|
        if @order_state.save
          format.html { redirect_to @order_state, :notice => 'Order state was successfully created.' }
          format.json { render :json => @order_state, :status => :created, :location => @order_state }
        else
          format.html { render :action => "new" }
          format.json { render :json => @order_state.errors, :status => :unprocessable_entity }
        end
      end
    end
  
    # PUT /order_states/1
    # PUT /order_states/1.json
    def update
      @order_state = OrderState.find(params[:id])
  
      respond_to do |format|
        if @order_state.update_attributes(params[:order_state])
          format.html { redirect_to @order_state, :notice => 'Order state was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render :action => "edit" }
          format.json { render :json => @order_state.errors, :status => :unprocessable_entity }
        end
      end
    end
  
    # DELETE /order_states/1
    # DELETE /order_states/1.json
    def destroy
      @order_state = OrderState.find(params[:id])
      @order_state.destroy
  
      respond_to do |format|
        format.html { redirect_to order_states_url }
        format.json { head :no_content }
      end
    end
  end
end
