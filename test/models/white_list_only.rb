class WhiteListOnly < ActiveRecord::Base

  white_list :only => [ :string_field1, :text_field1 ]
  
end
