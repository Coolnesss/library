require 'rails_helper'

describe "the signin process", :type => :feature do
  before :each do
    FactoryGirl.create :user
  end

  it "signs me in" do
    visit '/login'
    fill_in 'name', with: "John"
    fill_in 'password', with: 'Doe'
    click_button 'Submit'
    expect(page).to have_content 'Listing Books'
  end
end