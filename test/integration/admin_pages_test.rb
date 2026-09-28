require 'test_helper'

# Categories and Thoughts are admin-only for every action and format.
class AdminPagesTest < ActionDispatch::IntegrationTest
  test "readers are turned away from categories and thoughts" do
    sign_in users(:reader)

    [categories_path, thoughts_path, thoughts_path(format: :json)].each do |path|
      get path
      assert_redirected_to login_path, "expected #{path} to be admin-only"
    end
  end

  test "categories are admin-only, the JSON list included" do
    sign_in users(:reader)

    get categories_path(format: :json)
    assert_redirected_to login_path

    assert_no_difference 'Category.count' do
      post categories_path, params: { category: { name: 'Sneaky' } }
    end
    assert_redirected_to login_path
  end

  test "an admin manages categories" do
    sign_in users(:admin)

    get categories_path
    assert_response :success
    assert_includes response.body, 'Poetry'

    get categories_path(format: :json)
    assert_equal %w[History Poetry], response.parsed_body.map { |c| c['name'] }.sort

    assert_difference 'Category.count', 1 do
      post categories_path, params: { category: { name: 'Drama' } }
    end
    assert_difference 'Category.count', -1 do
      delete category_path(categories(:history))
    end
  end

  test "an admin manages thoughts" do
    sign_in users(:admin)

    get thoughts_path
    assert_response :success
    assert_includes response.body, '<strong>thought</strong>'

    assert_difference 'Thought.count', 1 do
      post thoughts_path, params: { thought: { content: 'ڪتاب', rtl: '1' } }
    end
    assert_redirected_to thoughts_path
    assert Thought.last.rtl
  end
end
