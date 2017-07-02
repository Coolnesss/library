require 'rails_helper'

def sign_in(credentials)
  visit login_path
  fill_in('name', with:credentials[:name])
  fill_in('password', with:credentials[:password])
  click_button('Submit')
end