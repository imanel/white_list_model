require 'test_helper'

class WhiteListModelTest < ActiveSupport::TestCase

  test "should not sanitize not whitelisted models" do
    model = WhiteListNone.create(unsanitized_hash)
    unsanitized_hash.keys.each do |key|
      assert_equal unsanitized_hash[key], model.attributes[key.to_s]
    end
  end

  test "should complete sanitize whitelisted models" do
    model = WhiteListAll.create(unsanitized_hash)
    unsanitized_hash.keys.each do |key|
      assert_equal sanitized_hash[key], model.attributes[key.to_s]
    end
  end

  test "should sanitize whitelisted models without :except fields" do
    model = WhiteListExcept.create(unsanitized_hash)
    unsanitized_hash.reject{ |key,value| model.white_list_options[:except].include?(key) }.keys.each do |key|
      assert_equal sanitized_hash[key], model.attributes[key.to_s]
    end
    model.white_list_options[:except].each do |key|
      assert_equal unsanitized_hash[key], model.attributes[key.to_s]
    end
  end

  test "should not sanitize whitelisted models except :only fields" do
    model = WhiteListOnly.create(unsanitized_hash)
    unsanitized_hash.reject{ |key,value| model.white_list_options[:only].include?(key) }.keys.each do |key|
      assert_equal unsanitized_hash[key], model.attributes[key.to_s]
    end
    model.white_list_options[:only].each do |key|
      assert_equal sanitized_hash[key], model.attributes[key.to_s]
    end
  end

  protected

  def unsanitized_hash
    {
      :boolean_field => true,
      :date_field => Date.new(2009,05,30),
      :datetime_field => DateTime.parse("10:15 2009-05-30"),
      :float_field => 3.1415,
      :integer_field => 112,
      :string_field1 => "Test string <b>bold</b> <i>italic</i> <u>underscore</u> <script>script</script> <abstract>content</abstract>",
      :string_field2 => "Test string <b>bold</b> <i>italic</i> <u>underscore</u> <script>script</script> <abstract>content</abstract>",
      :text_field1 => "Test string <b>bold</b> <i>italic</i> <u>underscore</u> <script>script</script> <abstract>content</abstract>",
      :text_field2 => "Test string <b>bold</b> <i>italic</i> <u>underscore</u> <script>script</script> <abstract>content</abstract>",
      :time_field => Time.parse("10:15 2009-05-30")
    }
  end

  def sanitized_hash
    unsanitized_hash.merge({
      :string_field1 => "Test string <b>bold</b> <i>italic</i> <u>underscore</u>  &lt;abstract>content&lt;/abstract>",
      :string_field2 => "Test string <b>bold</b> <i>italic</i> <u>underscore</u>  &lt;abstract>content&lt;/abstract>",
      :text_field1 => "Test string <b>bold</b> <i>italic</i> <u>underscore</u>  &lt;abstract>content&lt;/abstract>",
      :text_field2 => "Test string <b>bold</b> <i>italic</i> <u>underscore</u>  &lt;abstract>content&lt;/abstract>"
    })
  end
  
end
