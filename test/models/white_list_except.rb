class WhiteListExcept < ActiveRecord::Base

  white_list :except => [ :string_field1, :text_field1 ]
  
end
