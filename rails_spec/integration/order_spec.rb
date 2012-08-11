require 'spec_helper'

describe "Orders" do

  it "creating a new one" do
    visit orders_path
    click_link "New Order"
    fill_in "Contract", :with => 131313
    fill_in "Limit price", :with => 11.22
    fill_in "Order type", :with => 'STPLMT'
    fill_in "Side", :with => 'B'
    check "Transmit"
    click_button "Create Order"

    within "#notice" do
      page.should have_content("Order was successfully created.")
    end
    # p (page.methods-Object.methods).sort
    # p page.body
    page.should have_content("131313")
    page.should have_content("11.22")
    page.should have_content("stop_limit")
    page.should have_content("buy")
    page.should have_content("true")

  end
end