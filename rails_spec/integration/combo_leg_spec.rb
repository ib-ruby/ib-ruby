require 'spec_helper'

describe "Combo Leg" do

  it "creating a new one" do
    visit combo_legs_path
    click_link "New Combo Leg"
    fill_in "Combo", :with => 131313
    fill_in "Leg contract", :with => 141414
    fill_in "Con", :with => 151515
    fill_in "Side", :with => 'S'
    fill_in "Ratio", :with => 12
    fill_in "Exchange", :with => 'NYMEX'
    fill_in "Exempt code", :with => -1
    fill_in "Short sale slot", :with => 1
    fill_in "Open close", :with => 1
    click_button "Create Combo leg"

    within "#notice" do
      page.should have_content("Combo leg was successfully created.")
    end
    # p (page.methods-Object.methods).sort
    # p page.body
    page.should have_content("131313")
    page.should have_content("141414")
    page.should have_content("151515")
    page.should have_content("sell")
    page.should have_content("12")
    page.should have_content("NYMEX")
    page.should have_content("-1")
    page.should have_content("broker")
    page.should have_content("open")
  end
end
