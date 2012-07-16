require 'spec_helper'

describe "underlyings" do

  it "creating a new one" do
    visit underlyings_path
    click_link "New Underlying"
    fill_in "Contract", :with => 131313
    fill_in "Con", :with => 1111
    fill_in "Delta", :with => 14.15
    fill_in "Price", :with => 16.17
    click_button "Create Underlying"

    within "#notice" do
      page.should have_content("Underlying was successfully created.")
    end
    p (page.methods-Object.methods).sort
    p page.body
    page.should have_content("131313")
    page.should have_content("1111")
    page.should have_content("14.15")
    page.should have_content("16.17")

  end
end
