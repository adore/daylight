##
# Support for read_only attributes.
#
# Attributes that are read_only are specified in the metadata from the response
# from the API.
#
# Uses that information to keep from sending those read_only attributes in
# subsequent requests to the API.
#
# This is useful for computational values that are served that do not have
# corresponding column in the data store.

module Daylight::ReadOnly
  ##
  # Get the list of read_only attributes from the metadata attribute.
  # If there are none then an empty array is supplied.
  #
  # See:
  # metadata

  def read_only
    metadata[:read_only] || []
  end

  ##
  # Adds API specific options when generating json.
  # Removes read_only attributes for requests.
  #
  # See
  # except_read_only

  def as_json(options={})
    super(except_read_only(options))
  end

  ##
  # Adds API specific options when generating xml.
  # Removes read_only attributes for requests.
  #
  # See
  # except_read_only

  def to_xml(options={})
    super(except_read_only(options))
  end

  ##
  # Writers for read_only attributes are not included as methods
  #--
  # This is how we continue to prevent these read_only attributes to be set
  # internally by removing ActiveResource's ability to set their values

  def respond_to?(method_name, include_priv = false)
    return false if read_only?(method_name)
    super
  end

  private
    ##
    # Extends `method_missing` to raise an error when attempting to set a
    # read_only attribute.
    #
    # Otherwise it continues with the `ActiveResource::Base#method_missing`
    # functionality.

    def method_missing(method_name, *arguments)
      if read_only?(method_name)
        logger.warn "Cannot set read_only attribute: #{method_name[0...-1]}" if logger
        raise NoMethodError, "Cannot set read_only attribute: #{method_name[0...-1]}"
      end

      super
    end

    ##
    # Ensures that read_only attributes are merged in with `:except` options.

    def except_read_only options
      options.merge(except: (options[:except]||[]).push(*read_only))
    end

    ##
    # Determines if `method_name` is writing to a read_only attribute.

    def read_only? method_name
      !!(method_name =~ /(?:=)$/ && read_only.include?($`))
    end
end
