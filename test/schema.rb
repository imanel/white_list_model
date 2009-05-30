ActiveRecord::Schema.define(:version => 0) do

  create_table "white_list_tests", :force => true do |t|
    t.boolean  "boolean_field"
    t.date     "date_field"
    t.datetime "datetime_field"
    t.float    "float_field"
    t.integer  "integer_field"
    t.string   "string_field1"
    t.string   "string_field2"
    t.text     "text_field1"
    t.text     "text_field2"
    t.time     "time_field"
  end

end
