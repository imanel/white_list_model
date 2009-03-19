module WhiteListModel

  PROFILES = {
    :empty => {
      :attributes => [],
      :bad_tags => [],
      :protocols => [],
      :tags => []
    },
    :mini => {
      :attributes => [],
      :bad_tags => %w(script),
      :protocols => %w(ed2k ftp http https irc mailto news gopher nntp telnet webcal xmpp callto feed),
      :tags => []
    },
    :base => {
      :attributes => %w(href src),
      :bad_tags => %w(script),
      :protocols => %w(ed2k ftp http https irc mailto news gopher nntp telnet webcal xmpp callto feed),
      :tags => %w(b i u strike br)
    },
    :web => {
      :attributes => %w(href src),
      :bad_tags => %w(script),
      :protocols => %w(ed2k ftp http https irc mailto news gopher nntp telnet webcal xmpp callto feed),
      :tags => %w(b u i strike br ul ol li)
    },
    :default => {
      :attributes => %w(href src width height alt cite datetime title class),
      :bad_tags => %w(script),
      :protocols => %w(ed2k ftp http https irc mailto news gopher nntp telnet webcal xmpp callto feed),
      :tags => %w(strong em b i u p code pre tt output samp kbd var sub sup dfn cite big small address hr br div span h1 h2 h3 h4 h5 h6 ul ol li dt dd abbr acronym a img blockquote del ins fieldset legend)
    }
  }

  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods

    def white_list(options = {})
      before_validation :white_list_fields

      write_inheritable_attribute(:white_list_options, {
        :only       => (options[:only] || []),
        :except     => (options[:except] || []),
        :attributes => (options[:attributes] || []),
        :bad_tags   => (options[:bad_tags] || []),
        :protocols  => (options[:protocols] || []),
        :tags       => (options[:tags] || []),
        :profile    => (options[:profile] || :default)
      })

      class_inheritable_reader :white_list_options

      include WhiteListModel::InstanceMethods
    end

  end

  module InstanceMethods

    def white_list_fields
      # fix a bug with Rails internal AR::Base models that get loaded before
      # the plugin, like CGI::Sessions::ActiveRecordStore::Session
      return if white_list_options.nil?

      opts = {}
      profiles = WhiteListModel::PROFILES
      profile = ( profiles.include?(white_list_options[:profile].to_sym) )? profiles[white_list_options[:profile].to_sym] : profiles[:default]
      opts[:attributes] = (profile[:attributes] + white_list_options[:attributes]).uniq
      opts[:bad_tags] = (profile[:bad_tags] + white_list_options[:bad_tags]).uniq
      opts[:protocols] = (profile[:protocols] + white_list_options[:protocols]).uniq
      opts[:tags] = (profile[:tags] + white_list_options[:tags]).uniq


      self.class.columns.each do |column|
        next unless (column.type == :string || column.type == :text)

        field = column.name.to_sym
        value = self[field]

        next if value.nil?

        if white_list_options[:only]
          self[field] = white_list_parse(value, opts ) if white_list_options[:only].include?(field)
        else
          self[field] = white_list_parse(value, opts ) unless white_list_options[:except].include?(field)
        end
      end
    end

    protected
      def white_list_parse(text, options = {})
        protocol_attributes = Set.new %w(src href)
        return text if text.blank? || !text.include?('<')
        attrs    = Set.new(options[:attributes])
        bad_tags = Set.new(options[:bad_tags])
        prot     = Set.new(options[:protocols])
        tags     = Set.new(options[:tags])
        @included_bad_tags = []
        returning [] do |new_text|
          tokenizer = HTML::Tokenizer.new(text)
          bad       = nil
          while token = tokenizer.next
            node = HTML::Node.parse(nil, 0, 0, token, false)
            new_text << case node
              when HTML::Tag
                node.attributes.keys.each do |attr_name|
                  value = node.attributes[attr_name].to_s
                  if !attrs.include?(attr_name) || (protocol_attributes.include?(attr_name) && contains_bad_protocols?(value, prot))
                    node.attributes.delete(attr_name)
                  else
                    node.attributes[attr_name] = CGI::escapeHTML(value)
                  end
                end if node.attributes
                if tags.include?(node.name)
                  node
                elsif bad_tags.include?(node.name)
                  indent_bad_tag(node)
                else
                  node.to_s.gsub(/</, '&lt;') if @included_bad_tags.empty?
                end
              else
                node.to_s.gsub(/</, '&lt') if @included_bad_tags.empty?
            end
          end
        end.join
      end

      def indent_bad_tag(tag)
        case tag.closing
        when nil then @included_bad_tags << tag.name
        when :close then @included_bad_tags.delete_at( @included_bad_tags.index(tag.name) ) rescue nil
        else nil
        end
        nil
      end

      def contains_bad_protocols?(value, protocols)
        protocol_separator  = /:|(&#0*58)|(&#x70)|(%|&#37;)3A/
        value =~ protocol_separator && !protocols.include?(value.split(protocol_separator).first)
      end

  end
end
