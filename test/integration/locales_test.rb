require 'test_helper'

class LocalesTest < ActionDispatch::IntegrationTest
  test "pages are in Sindhi, right to left, until the visitor switches" do
    get login_path
    assert_select 'html[lang=sd][dir=rtl]'
    assert_select 'h1', 'داخل ٿيو'

    patch locale_path, params: { locale: 'en' }, headers: { 'HTTP_REFERER' => login_url }
    assert_redirected_to login_url

    get login_path
    assert_select 'html[lang=en][dir=ltr]'
    assert_select 'h1', 'Sign in'
  end

  test "the language menu shows the current language, ticked, and offers the other" do
    get login_path
    assert_select '.language-menu summary', /سنڌي/
    assert_select '.language-menu .language-current[aria-current]', /✓\s*سنڌي/
    assert_select '.language-menu form[action=?] input[name=locale][value=en]', locale_path
  end

  test "an unknown locale falls back to Sindhi" do
    patch locale_path, params: { locale: 'fr' }
    get login_path
    assert_select 'html[lang=sd]'
  end

  test "a signed-in user's choice is saved and wins over the browser's" do
    sign_in users(:reader)
    patch locale_path, params: { locale: 'en' }
    assert_equal 'en', users(:reader).reload.locale

    cookies[:locale] = 'sd'
    get books_path
    assert_select 'html[lang=en]'
  end

  test "registering records the page's language for the approval email" do
    patch locale_path, params: { locale: 'en' }
    post users_path, params: { user: { name: 'New', email: 'new@example.com', password: 'secret12', password_confirmation: 'secret12' } }
    assert_equal 'en', User.find_by(email: 'new@example.com').locale
  end

  test "admin pages stay left to right on Sindhi pages" do
    sign_in users(:admin)
    get categories_path
    assert_select 'html[dir=rtl]'
    assert_select 'div[lang=en][dir=ltr]'
  end
end
