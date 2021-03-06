require "wrong/chunk"

module Wrong
  def self.load_config
    settings = begin
      Chunk.read_here_or_higher(".wrong")
    rescue Errno::ENOENT => e
      # couldn't find it
      nil # In Ruby 1.8, "e" would be returned here otherwise
    end
    Config.new settings
  end

  def self.config
    @config ||= load_config
  end

  def self.config=(new_config)
    @config = load_config
  end

  class Config < Hash
     def initialize(string = nil)
      self[:aliases] = {:assert => [:assert], :deny => [:deny]}
      if string
        instance_eval string.gsub(/^(.*=)/, "self.\\1")
      end
    end

    def method_missing(name, value = true)
      name = name.to_s
      if name =~ /=$/
        name.gsub!(/=$/, '')
      end
      self[name.to_sym] = value
    end

    def alias_assert_or_deny(valence, extra_name)
      Wrong::Assert.send(:alias_method, extra_name, valence)
      new_method_name = extra_name.to_sym
      self[:aliases][valence] << new_method_name unless self[:aliases][valence].include?(new_method_name)
    end

    def alias_assert(method_name)
      alias_assert_or_deny(:assert, method_name)
    end

    def alias_deny(method_name)
      alias_assert_or_deny(:deny, method_name)
    end

    def assert_method_names
      self[:aliases][:assert]
    end

    def deny_method_names
      self[:aliases][:deny]
    end

    def assert_methods
      assert_method_names + deny_method_names
    end
  end
end
