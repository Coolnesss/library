require 'rails_helper'

RSpec.describe "thoughts/show", type: :view do
  before(:each) do
    @thought = assign(:thought, Thought.create!(
      :content => "MyText",
      :rtl => false
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/false/)
  end
end
