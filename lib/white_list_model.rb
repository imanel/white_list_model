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
      update_white_list_options(options)
      class_inheritable_reader :white_list_options
      include WhiteListModel::InstanceMethods
    end

    protected

    def update_white_list_options(options)
      opts = read_inheritable_attribute(:white_list_options) || {}
      only = options.delete(:only)
      except = options.delete(:except)
      method = options.delete(:method)
      method = :replace unless [ :replace, :update ].include?(method)
      options = format_white_list_options(options)
      
      return if only && except

      if only.nil? && except.nil?
        opts = {} if method == :replace
        opts[:white_list_defaults] = options
      elsif only
        opts = {} if method == :replace
        only.to_a.each do |key|
          opts[key] = options
        end
      else
        new_options = { :white_list_defaults => options }
        except.to_a.each do |e|
          new_options[e] = ( method == :replace ? 0 : opts[e] || 0 )
        end
        opts = new_options
      end
      write_inheritable_attribute(:white_list_options, opts)
    end

    def format_white_list_options(options)
      opts = {
        :attributes => options[:attributes] || [],
        :bad_tags   => options[:bad_tags]   || [],
        :profile    => options[:profile]    || :default,
        :protocols  => options[:protocols]  || [],
        :tags       => options[:tags]       || []
      }
      opts
    end
    
  end

  module InstanceMethods

    def white_list_fields
      # fix a bug with Rails internal AR::Base models that get loaded before
      # the plugin, like CGI::Sessions::ActiveRecordStore::Session
      return if white_list_options.nil? || !white_list_options.is_a?(Hash)

      profiles = WhiteListModel::PROFILES

      self.class.columns.each do |column|
        next unless (column.type == :string || column.type == :text)

        field = column.name.to_sym
        value = self[field]

        next if value.nil?

        field_options = white_list_options[field] || white_list_options[:white_list_defaults]
        next if field_options.nil? || field_options == 0

        opts = {}
        profile = ( profiles.keys.include?(field_options[:profile].to_sym) )? profiles[field_options[:profile].to_sym] : profiles[:default]
        opts[:attributes] = (profile[:attributes] + field_options[:attributes]).uniq
        opts[:bad_tags]   = (profile[:bad_tags]   + field_options[:bad_tags]).uniq
        opts[:protocols]  = (profile[:protocols]  + field_options[:protocols]).uniq
        opts[:tags]       = (profile[:tags]       + field_options[:tags]).uniq

        self[field] = white_list_parse(value, opts )
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
                node.to_s.gsub(/</, '&lt;') if @included_bad_tags.empty?
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
