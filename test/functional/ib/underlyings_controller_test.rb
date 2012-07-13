require 'test_helper'

module Ib
  class UnderlyingsControllerTest < ActionController::TestCase
    setup do
      @underlying = underlyings(:one)
    end
  
    test "should get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:underlyings)
    end
  
    test "should get new" do
      get :new
      assert_response :success
    end
  
    test "should create underlying" do
      assert_difference('Underlying.count') do
        post :create, :underlying => { :con_id => @underlying.con_id, :delta => @underlying.delta, :price => @underlying.price }
      end
  
      assert_redirected_to underlying_path(assigns(:underlying))
    end
  
    test "should show underlying" do
      get :show, :id => @underlying
      assert_response :success
    end
  
    test "should get edit" do
      get :edit, :id => @underlying
      assert_response :success
    end
  
    test "should update underlying" do
      put :update, :id => @underlying, :underlying => { :con_id => @underlying.con_id, :delta => @underlying.delta, :price => @underlying.price }
      assert_redirected_to underlying_path(assigns(:underlying))
    end
  
    test "should destroy underlying" do
      assert_difference('Underlying.count', -1) do
        delete :destroy, :id => @underlying
      end
  
      assert_redirected_to underlyings_path
    end
  end
end
