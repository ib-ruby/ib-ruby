require 'spec_helper'

describe "Executions" do

  it "creating a new one" do
    visit executions_path
    click_link "New Execution"
    fill_in "Order", :with => 131313
    fill_in "Local", :with => 121212
    fill_in "Client", :with => 141414
    fill_in "Perm", :with => 151515
    fill_in "Order ref", :with => 'cangaroo'
    fill_in "Exec", :with => '0001f4e8.4f5d48f1.01.02'
    fill_in "Side", :with => 's'
    fill_in "Quantity", :with => 111111
    fill_in "Cumulative quantity", :with => 222222
    fill_in "Price", :with => 11.22
    fill_in "Average price", :with => 12.33
    fill_in "Exchange", :with => "IDEALPRO"
    check "Liquidation"
    fill_in "Time", :with => "20120312 15:41:09"
    click_button "Create Execution"

    within "#notice" do
      page.should have_content("Execution was successfully created.")
    end
    # p (page.methods-Object.methods).sort
    # p page.body
    page.should have_content("131313")
    page.should have_content("141414")
    page.should have_content("151515")
    page.should have_content("121212")
    page.should have_content("cangaroo")
    page.should have_content("0001f4e8.4f5d48f1.01.02")
    page.should have_content("sell")
    page.should have_content("111111")
    page.should have_content("222222")
    page.should have_content("11.22")
    page.should have_content("12.33")
    page.should have_content("IDEALPRO")
    page.should have_content("true")
    page.should have_content("20120312 15:41:09")

  end
end
