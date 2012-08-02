require 'spec_helper'

describe "OrderStates" do

  it "creating a new one" do
    visit order_states_path
    click_link "New Order State"
    fill_in "Order", :with => 131313
    fill_in "Local", :with => 121212
    fill_in "Client", :with => 141414
    fill_in "Perm", :with => 151515
    fill_in "Parent", :with => 161616
    fill_in "Status", :with => 'PreSubmitted'
    fill_in "Price", :with => 11.22
    fill_in "Average price", :with => 12.33
    fill_in "Why held", :with => 'child'
    fill_in "Commission", :with => 1.02
    fill_in "Min commission", :with => 1.01
    fill_in "Max commission", :with => 1.03
    fill_in "Commission currency", :with => "EUR"
    fill_in "Init margin", :with => 22.22
    fill_in "Maint margin", :with => 33.33
    fill_in "Equity with loan", :with => 44.44
    click_button "Create Order state"

    within "#notice" do
      page.should have_content("Order state was successfully created.")
    end
    # p (page.methods-Object.methods).sort
    # p page.body
    page.should have_content("131313")
    page.should have_content("141414")
    page.should have_content("151515")
    page.should have_content("161616")
    page.should have_content("121212")
    page.should have_content("PreSubmitted")
    page.should have_content("child")
    page.should have_content("11.22")
    page.should have_content("12.33")
    page.should have_content("1.01")
    page.should have_content("1.02")
    page.should have_content("1.03")
    page.should have_content("EUR")
    page.should have_content("22.22")
    page.should have_content("33.33")
    page.should have_content("44.44")

  end
end
