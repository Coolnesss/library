require 'rails_helper'

RSpec.describe "Thoughts", type: :request do
  describe "GET /thoughts" do
    it "works! (now write some real specs)" do
      get thoughts_path
      expect(response).to have_http_status(200)
    end
  end
end
