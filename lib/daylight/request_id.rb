class Daylight::RequestId
  delegate :strip, to: :to_s
  attr_accessor :client_id, :custom_id

  def initialize client_id=nil
    @client_id = client_id
  end

  def generate
    [SecureRandom.uuid, client_id].compact.join('/')
  end

  def use id=generate
    self.custom_id = id

    if block_given?
      yield custom_id
      clear!
    else
      custom_id
    end
  end

  def clear!
    @custom_id = nil
  end

  def current
    custom_id || @request_id = generate
  end
  alias_method :to_s, :current

  def previous
    @request_id ||= current
  end

  def inspect
    "\"#{current}\""
  end
end