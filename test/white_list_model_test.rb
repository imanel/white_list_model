require 'test_helper'

class WhiteListModelTest < ActiveSupport::TestCase

  test "should handle non html" do
    assert_white_listed "abcd", "abcd"
  end

  test "should handle blank text" do
    assert_white_listed nil, nil
  end

  test "should sanitize whitelisted models" do
    WhiteListTest.send(:white_list)
    model = WhiteListTest.create(unsanitized_hash)
    unsanitized_hash.keys.each do |key|
      assert_equal sanitized_hash[key], model.attributes[key.to_s]
    end
  end

  test "should sanitize whitelisted models without :except fields" do
    WhiteListTest.send(:white_list, :except => altered_fields)
    model = WhiteListTest.create(unsanitized_hash)
    unsanitized_hash.reject{ |key,value| altered_fields.include?(key) }.keys.each do |key|
      assert_equal sanitized_hash[key], model.attributes[key.to_s]
    end
    altered_fields.each do |key|
      assert_equal unsanitized_hash[key], model.attributes[key.to_s]
    end
  end

  test "should not sanitize whitelisted models except :only fields" do
    WhiteListTest.send(:white_list, :only => altered_fields)
    model = WhiteListTest.create(unsanitized_hash)
    unsanitized_hash.reject{ |key,value| altered_fields.include?(key) }.keys.each do |key|
      assert_equal unsanitized_hash[key], model.attributes[key.to_s]
    end
    altered_fields.each do |key|
      assert_equal sanitized_hash[key], model.attributes[key.to_s]
    end
  end

  test "should allow to replace default whitelist options" do
    WhiteListTest.send(:white_list, :only => altered_fields)
    model = WhiteListTest.create(unsanitized_hash)
    unsanitized_hash.reject{ |key,value| altered_fields.include?(key) }.keys.each do |key|
      assert_equal unsanitized_hash[key], model.attributes[key.to_s]
    end
    altered_fields.each do |key|
      assert_equal sanitized_hash[key], model.attributes[key.to_s]
    end
    WhiteListTest.send(:white_list)
    model = WhiteListTest.create(unsanitized_hash)
    unsanitized_hash.keys.each do |key|
      assert_equal sanitized_hash[key], model.attributes[key.to_s]
    end
  end

  test "should allow only tags from profile" do
    good_tags = WhiteListModel::PROFILES[:base][:tags]
    bad_tags = WhiteListModel::PROFILES[:default][:tags] - good_tags
    unsanitized_string = ""
    sanitized_string = ""
    good_tags.each do |tag|
      unsanitized_string += "<#{tag}> "
      sanitized_string += "<#{tag}> "
    end
    bad_tags.each do |tag|
      unsanitized_string += "<#{tag}> temp </#{tag}> "
      sanitized_string += "&lt;#{tag}> temp &lt;/#{tag}> "
    end
    good_tags.each do |tag|
      unsanitized_string += "</#{tag}> "
      sanitized_string += "</#{tag}> "
    end
    assert_white_listed unsanitized_string, sanitized_string, :profile => :base
  end

  test "should allow add custom tags to profile" do
    WhiteListTest.send(:white_list, :profile => :base, :tags => %w(a x))
    good_tags = WhiteListModel::PROFILES[:base][:tags] + %w(a x)
    bad_tags = WhiteListModel::PROFILES[:default][:tags] - good_tags
    unsanitized_string = ""
    sanitized_string = ""
    good_tags.each do |tag|
      unsanitized_string += "<#{tag}> "
      sanitized_string += "<#{tag}> "
    end
    bad_tags.each do |tag|
      unsanitized_string += "<#{tag}> temp </#{tag}> "
      sanitized_string += "&lt;#{tag}> temp &lt;/#{tag}> "
    end
    good_tags.each do |tag|
      unsanitized_string += "</#{tag}> "
      sanitized_string += "</#{tag}> "
    end
    model = WhiteListTest.create( :text_field1 => unsanitized_string )
    assert_equal sanitized_string, model.text_field1
  end

  test "should allow only attributes from profile" do
    good_attributes = WhiteListModel::PROFILES[:base][:attributes]
    bad_attributes = WhiteListModel::PROFILES[:default][:attributes] - good_attributes
    unsanitized_string = "<" + WhiteListModel::PROFILES[:base][:tags].first
    sanitized_string = "<" + WhiteListModel::PROFILES[:base][:tags].first
    good_attributes.each do |attr|
      unsanitized_string += " #{attr}=\"1\""
      sanitized_string += " #{attr}=\"1\""
    end
    bad_attributes.each do |attr|
      unsanitized_string += " #{attr}=\"1\""
      sanitized_string += ""
    end
    unsanitized_string += ">"
    sanitized_string += ">"
    assert_white_listed unsanitized_string, sanitized_string, :profile => :base
  end

  test "should allow adding attributes to profile" do
    good_attributes = WhiteListModel::PROFILES[:base][:attributes] + %w(alt test)
    bad_attributes = WhiteListModel::PROFILES[:default][:attributes] - good_attributes
    unsanitized_string = "<" + WhiteListModel::PROFILES[:base][:tags].first
    sanitized_string = "<" + WhiteListModel::PROFILES[:base][:tags].first
    good_attributes.each do |attr|
      unsanitized_string += " #{attr}=\"1\""
      sanitized_string += " #{attr}=\"1\""
    end
    bad_attributes.each do |attr|
      unsanitized_string += " #{attr}=\"1\""
      sanitized_string += ""
    end
    unsanitized_string += ">"
    sanitized_string += ">"
    assert_white_listed unsanitized_string, sanitized_string, :profile => :base, :attributes => %w(alt test)
  end

  test "should allow only protocols from profile" do
    unsanitized_string = "<a"
    unsanitized_string += " href=\"#{WhiteListModel::PROFILES[:base][:protocols].first}://test\""
    unsanitized_string += " src=\"#{WhiteListModel::PROFILES[:base][:protocols].last}://test\""
    unsanitized_string += ">"
    sanitized_string = "<a>"
    assert_white_listed unsanitized_string, sanitized_string, :profile => :empty, :tags => %w(a)
    assert_white_listed unsanitized_string, unsanitized_string, :profile => :base, :tags => %w(a)
  end

  test "should allow adding protocols to profile" do
    assert_white_listed "<a href=\"http://test\" src=\"abstract://test\">", "<a href=\"http://test\">", :profile => :default
    assert_white_listed "<a href=\"http://test\" src=\"abstract://test\">", "<a href=\"http://test\" src=\"abstract://test\">", :profile => :default, :protocols => %w(abstract)
  end

  test "should completly strip bad tags from profile" do
    assert_white_listed "abcd<script>1234</script>efgh", "abcd&lt;script>1234&lt;/script>efgh", :profile => :empty
    assert_white_listed "abcd<script>1234</script>efgh", "abcdefgh", :profile => :base
  end

  test "should allow adding bad tags to profile" do
    assert_white_listed "abcd<test>1234</test>efgh", "abcd&lt;test>1234&lt;/test>efgh", :profile => :base
    assert_white_listed "abcd<test>1234</test>efgh", "abcdefgh", :profile => :base, :bad_tags => %w(test)
  end

  # Test from white_list helper

  test "should reject hex codes in protocol" do
    assert_white_listed "<a href=\"%6A%61%76%61%73%63%72%69%70%74%3A%61%6C%65%72%74%28%22%58%53%53%22%29\">", "<a>"
  end

  test "should not fall for xss image hacks" do
    [%(<IMG SRC="javascript:alert('XSS');">),
     %(<IMG SRC=javascript:alert('XSS')>),
     %(<IMG SRC=JaVaScRiPt:alert('XSS')>),
     %(<IMG """><SCRIPT>alert("XSS")</SCRIPT>">),
     %(<IMG SRC=javascript:alert(&quot;XSS&quot;)>),
     %(<IMG SRC=javascript:alert(String.fromCharCode(88,83,83))>),
     %(<IMG SRC=&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;&#97;&#108;&#101;&#114;&#116;&#40;&#39;&#88;&#83;&#83;&#39;&#41;>),
     %(<IMG SRC=&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041>),
     %(<IMG SRC=&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29>),
     %(<IMG SRC="jav\tascript:alert('XSS');">),
     %(<IMG SRC="jav&#x09;ascript:alert('XSS');">),
     %(<IMG SRC="jav&#x0A;ascript:alert('XSS');">),
     %(<IMG SRC="jav&#x0D;ascript:alert('XSS');">),
     %(<IMG SRC=" &#14;  javascript:alert('XSS');">),
     %(<IMG SRC=`javascript:alert("RSnake says, 'XSS'")`>)].each do |string|
      assert_white_listed string, "<img>"
    end
  end

  test "should sanitize tag broken up by null" do
    assert_white_listed %(<SCR\0IPT>alert(\"XSS\")</SCR\0IPT>), "&lt;scr>alert(\"XSS\")&lt;/scr>"
  end

  test "should sanitize invalid script tag" do
    assert_white_listed %(<SCRIPT/XSS SRC="http://ha.ckers.org/xss.js"></SCRIPT>), ""
  end

  test "should sanitize script tag with multiple open brackets" do
    assert_white_listed %(<<SCRIPT>alert("XSS");//<</SCRIPT>), "&lt;"
    assert_white_listed %(<iframe src=http://ha.ckers.org/scriptlet.html\n<), %(&lt;iframe src="http:" />&lt;)
  end

  test "should sanitize unclosed script" do
    assert_white_listed %(<SCRIPT SRC=http://ha.ckers.org/xss.js?<B>), "<b>"
  end

  test "should sanitize half open scripts" do
    assert_white_listed %(<IMG SRC="javascript:alert('XSS')"), "<img>"
  end

  test "should not fall for ridiculous hack" do
    img_hack = %(<IMG\nSRC\n=\n"\nj\na\nv\na\ns\nc\nr\ni\np\nt\n:\na\nl\ne\nr\nt\n(\n'\nX\nS\nS\n'\n)\n"\n>)
    assert_white_listed img_hack, "<img>"
  end

  protected

  def altered_fields
    [:string_field1, :text_field1]
  end

  def assert_white_listed( unsanitized_string, sanitized_string, options = {} )
    WhiteListTest.send(:white_list, options)
    model = WhiteListTest.create( :text_field1 => unsanitized_string )
    assert_equal sanitized_string, model.text_field1
  end

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
