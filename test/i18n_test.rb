require 'test_helper'

# Every English text needs a Sindhi one, and the other way round; a missing
# Sindhi text would silently show in English.
class I18nTest < ActiveSupport::TestCase
  def keys(locale)
    flatten(YAML.load_file(Rails.root.join("config/locales/#{locale}.yml")).fetch(locale))
  end

  def flatten(hash, prefix = nil)
    hash.flat_map do |key, value|
      path = [prefix, key].compact.join('.')
      value.is_a?(Hash) ? flatten(value, path) : [path]
    end
  end

  test "sd.yml and en.yml have the same keys" do
    assert_equal [], keys('en') - keys('sd'), 'missing in sd.yml'
    assert_equal [], keys('sd') - keys('en'), 'missing in en.yml'
  end
end
