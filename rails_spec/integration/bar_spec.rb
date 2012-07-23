require 'spec_helper'

describe "Bars" do

  it "creating a new one" do
    visit bars_path
    click_link "New Bar"
    fill_in "Contract", :with => 131313
    fill_in "Open", :with => 11.22
    fill_in "High", :with => 14.15
    fill_in "Low", :with => 10.11
    fill_in "Close", :with => 13.14
    fill_in "Wap", :with => 12.13
    fill_in "Volume", :with => 1111
    fill_in "Trades", :with => 444
    check "Has gaps"
    fill_in "Time", :with => "20120312 15:41:09"
    click_button "Create Bar"

    within "#notice" do
      page.should have_content("Bar was successfully created.")
    end
    # p (page.methods-Object.methods).sort
    # p page.body
    page.should have_content("131313")
    page.should have_content("11.22")
    page.should have_content("14.15")
    page.should have_content("10.11")
    page.should have_content("13.14")
    page.should have_content("12.13")
    page.should have_content("1111")
    page.should have_content("444")
    page.should have_content("true")
    page.should have_content("20120312 15:41:09")

  end
end