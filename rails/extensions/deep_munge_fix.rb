# Rails' deep_munge nukes empty arrays out of params.
# Here we are allowing it so we can properly reset associations.
#
# see https://github.com/rails/rails/pull/11044
# and https://github.com/rails/rails/issues/13420

module DeepMungeFix
  def deep_munge(hash)
    hash.each do |k, v|
      case v
      when Array
        v.grep(Hash) { |x| deep_munge(x) }
        if v.empty?
          hash[k] = []
        else
          v.compact!
          hash[k] = nil if v.empty?
        end
      when Hash
        deep_munge(v)
      end
    end
    hash
  end
end

ActionDispatch::Request.class_eval do
  if self.const_defined? :Utils
    # for Rails 4.1
    self::Utils.class_eval do
      class << self
        prepend DeepMungeFix
      end
    end
  else
    # for Rails 4.0
    prepend DeepMungeFix
  end
end
