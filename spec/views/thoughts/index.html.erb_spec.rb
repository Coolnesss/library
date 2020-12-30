require 'rails_helper'

RSpec.describe "thoughts/index", type: :view do
  before(:each) do
    assign(:thoughts, [
      Thought.create!(
        :content => "MyText",
        :rtl => false
      ),
      Thought.create!(
        :content => "MyText",
        :rtl => false
      )
    ])
  end

  it "renders a list of thoughts" do
    render
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => false.to_s, :count => 2
  end
end
