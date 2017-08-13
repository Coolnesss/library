require 'rails_helper'

describe "Books", :type => :feature do
  before :each do
    FactoryGirl.create :user
    FactoryGirl.create :book
  end

  it "can view books list" do
    sign_in name: "John", password: "Doe"
    visit '/books'
    expect(page).to have_content 'Listing Books'
    expect(page).to have_content Book.first.name
  end

  it "can view single book" do
    sign_in name: "John", password: "Doe"
    visit "/books/1"
    expect(page).to have_content Book.first.name
  end
end