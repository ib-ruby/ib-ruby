require 'spec_helper'

describe "ContractDetails" do

  it "creating a new one" do
    visit contract_details_path
    click_link "New Contract Detail"
    fill_in "Market name", :with => 'AAPL'
    fill_in "Trading class", :with => 'AAPL'
    fill_in "Min tick", :with => 0.02
    fill_in "Price magnifier", :with => 100
    fill_in "Order types", :with => 'ACTIVETIM,ADJUST,ALERT,ALGO,ALLOC,AON,AVGCOST,BASKET,COND,CONDORDER,DAY,DEACT,DEACTDIS,DEACTEOD,FOK,GAT,GTC,GTD,GTT,HID,ICE,IOC,LIT,LMT,MIT,MKT,MTL,NONALGO,OCA,PAON,POSTONLY,RELSTK,SCALE,SCALERST,SMARTSTG,STP,STPLMT,TRAIL,TRAILLIT,TRAILLMT,TRAILMIT,VOLAT,WHATIF'
    fill_in "Valid exchanges", :with => 'SMART,AMEX,BATS,BOX,CBOE,CBOE2,IBSX,ISE,MIBSX,NASDAQOM,PHLX,PSE'
    fill_in "Under con", :with => 265598
    fill_in "Long name", :with => 'APPLE INC'
    fill_in "Contract month", :with => '201301'
    fill_in "Industry", :with => 'Technology'
    fill_in "Category", :with => 'Computers'
    fill_in "Subcategory", :with => 'Computers'
    fill_in "Time zone", :with => 'EST'
    fill_in "Trading hours", :with => '20120422:0930-1600;20120423:0930-1600'
    fill_in "Liquid hours", :with => '20120422:0930-1600;20120423:0930-1600'
    click_button "Create Contract detail"

    within "#notice" do
      page.should have_content("Contract detail was successfully created.")
    end
    # p (page.methods-Object.methods).sort
    # p page.body
    page.should have_content("AAPL")
    page.should have_content("0.02")
    page.should have_content("100")
    page.should have_content("ACTIVETIM,ADJUST,ALERT,ALGO,ALLOC,AON,AVGCOST,BASKET,COND,CONDORDER,DAY,DEACT,DEACTDIS,DEACTEOD,FOK,GAT,GTC,GTD,GTT,HID,ICE,IOC,LIT,LMT,MIT,MKT,MTL,NONALGO,OCA,PAON,POSTONLY,RELSTK,SCALE,SCALERST,SMARTSTG,STP,STPLMT,TRAIL,TRAILLIT,TRAILLMT,TRAILMIT,VOLAT,WHATIF")
    page.should have_content("SMART,AMEX,BATS,BOX,CBOE,CBOE2,IBSX,ISE,MIBSX,NASDAQOM,PHLX,PSE")
    page.should have_content("265598")
    page.should have_content("APPLE INC")
    page.should have_content("201301")
    page.should have_content("Technology")
    page.should have_content("Computers")
    page.should have_content("EST")
    page.should have_content("20120422:0930-1600;20120423:0930-1600")

  end
end
