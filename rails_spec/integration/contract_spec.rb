require 'spec_helper'

describe "Contracts" do

  it "creating a new one" do
    visit contracts_path
    click_link "New Contract"
    fill_in "Multiplier", :with => 131313
    fill_in "Strike", :with => 620.22
    fill_in "Right", :with => 'P'
    fill_in "Symbol", :with => 'AAPL'
    fill_in "Currency", :with => 'USD'
    fill_in "Exchange", :with => 'SMART'
    fill_in "Sec type", :with => 'OPT'
    fill_in "Sec", :with => 'US0378331005' # "Sec id" ?
    fill_in "Sec id type", :with => 'ISIN'
    click_button "Create Contract"

    within "#notice" do
      page.should have_content("Contract was successfully created.")
    end
    # p (page.methods-Object.methods).sort
    # p page.body
    page.should have_content("131313")
    page.should have_content("620.22")
    page.should have_content("put")
    page.should have_content("AAPL")
    page.should have_content("USD")
    page.should have_content("SMART")
    page.should have_content("option")
    page.should have_content("US0378331005")
    page.should have_content("ISIN")

  end
end