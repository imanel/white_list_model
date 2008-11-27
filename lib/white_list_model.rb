module WhiteListModel

  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods

    def white_list(options = {})
      before_save :white_list_fields

      write_inheritable_attribute(:white_list_options, {
        :only       => (options[:only] || []),
        :except     => (options[:except] || []),
        :tags       => (options[:tags] || []),
        :attributes => (options[:attributes] || [])
      })

      class_inheritable_reader :white_list_options

      include WhiteListModel::InstanceMethods
    end

  end

  module InstanceMethods

    include WhiteListHelper

    def white_list_fields
      # fix a bug with Rails internal AR::Base models that get loaded before
      # the plugin, like CGI::Sessions::ActiveRecordStore::Session
      return if white_list_options.nil?

      opts = {}
      opts[:attributes] = white_list_options[:attributes]
      opts[:tags] = white_list_options[:tags]

      self.class.columns.each do |column|
        next unless (column.type == :string || column.type == :text)

        field = column.name.to_sym
        value = self[field]

        next if value.nil?

        if white_list_options[:only]
          self[field] = white_list(value, opts ) if white_list_options[:only].include?(field)
        else
          self[field] = white_list(value, opts ) unless white_list_options[:except].include?(field)
        end
      end
    end
  end
end
