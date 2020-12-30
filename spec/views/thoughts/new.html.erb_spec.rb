require 'rails_helper'

RSpec.describe "thoughts/new", type: :view do
  before(:each) do
    assign(:thought, Thought.new(
      :content => "MyText",
      :rtl => false
    ))
  end

  it "renders new thought form" do
    render

    assert_select "form[action=?][method=?]", thoughts_path, "post" do

      assert_select "textarea[name=?]", "thought[content]"

      assert_select "input[name=?]", "thought[rtl]"
    end
  end
end
