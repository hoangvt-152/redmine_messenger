require File.expand_path '../../test_helper', __FILE__

class I18nTest < ActiveSupport::TestCase
  include Redmine::I18n

  def setup
    User.current = nil
  end

  def teardown
    set_language_if_valid 'en'
  end

  def test_valid_languages
    assert valid_languages.is_a?(Array)
    assert valid_languages.first.is_a?(Symbol)
  end

  def test_locales_validness
    lang_files_count = Dir[Rails.root.join('plugins/redmine_messenger/config/locales/*.yml')].size
    assert_equal lang_files_count, 5
    valid_languages.each do |lang|
      assert set_language_if_valid(lang)
    end
    # check if parse error exists
    ::I18n.locale = 'de'
    assert_equal 'Messenger Benutzer', l(:label_settings_messenger_username)
    ::I18n.locale = 'en'
    assert_equal 'Messenger username', l(:label_settings_messenger_username)
    ::I18n.locale = 'ja'
    assert_equal 'メッセンジャーのユーザー名', l(:label_settings_messenger_username)
    set_language_if_valid('en')
  end
end
