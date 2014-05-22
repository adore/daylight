class Array
  ##
  # Return any options without removing them from the Array.
  # This is a non-destrcutive version of `extract_options!`
  # Although the name is a misnomer, leaving it for consistency
  def extract_options
    last.is_a?(Hash) && last.extractable_options? ? last : {}
  end
end
