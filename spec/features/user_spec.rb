require 'rails_helper'

describe "User", :type => :feature do
  before :each do
    FactoryGirl.create :user
  end

  it "can sign in" do
    sign_in name: "John", password: "Doe"
    expect(page).to have_content 'Library'
  end

  it "can change password" do
    sign_in name: "John", password: "Doe"

    new_pass = "NewPassword"
    visit change_password_path

    fill_in 'user_password', with: new_pass 
    fill_in 'user_password_confirmation', with: new_pass
    click_button 'Submit'

    expect(page).to have_content 'Library'

    visit logout_path

    sign_in name: "John", password: new_pass
    expect(page).to have_content 'Library'
  end

end