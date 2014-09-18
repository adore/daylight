##
# Helper to generate a `uuid` for use in X-Request-Id
#
# In simplest form, provides ways to generate uuids on inspection
#
#   rid = Daylight::RequestId.new
#   puts rid # f3db9cf4-d2b3-4590-ade1-b9d8e7e57e6e
#   puts rid # b985486c-1d1f-434b-8138-c63e2102b07a
#
# You can also create a session to use the same `uuid`.
# For use in your Rack middleware or around_filters:
#
#   rid.use do |uuid|
#     puts uuid # 09354cfc-9f6e-4bdc-85c5-2adacf32ba42
#     puts rid  # 09354cfc-9f6e-4bdc-85c5-2adacf32ba42
#     yield
#     puts rid  # 09354cfc-9f6e-4bdc-85c5-2adacf32ba42
#   end
#
# You can supply a custom `uuid` for cases when it may have
# already been generated in your app:
#
#   rid.use("3a336db1-973e-4e5f-b82f-53de6cfb4c6c") do |uuid|
#     puts uuid # 3a336db1-973e-4e5f-b82f-53de6cfb4c6c
#     puts rid  # 3a336db1-973e-4e5f-b82f-53de6cfb4c6c
#     yield
#     puts rid  # 3a336db1-973e-4e5f-b82f-53de6cfb4c6c
#   end
#
# You can start a session without a block but must clear the session manually.
#
#   uuid = rid.use
#   puts uuid # c63a23bd-5f22-4a67-aed7-2e5bfa6b7f03
#   puts rid  # c63a23bd-5f22-4a67-aed7-2e5bfa6b7f03
#   puts rid  # c63a23bd-5f22-4a67-aed7-2e5bfa6b7f03
#
#   rid.clear!
#   puts rid  # a621cf03-ce12-4cff-98a2-50bc473de0fa

class Daylight::RequestId
  delegate :strip, to: :to_s
  attr_accessor :client_id, :custom_id

  ##
  # Creates a new RequestId.  You may supply a "client_id" which will
  # be appended to the `uuid`:
  #
  # rid = Daylight::RequestId.new('test')
  # puts rid # 58c0331e-b545-4ec8-ac6d-88078a9c21d8/test

  def initialize client_id=nil
    @client_id = client_id
  end

  ##
  # Generates a new `uuid`
  def generate
    [SecureRandom.uuid, client_id].compact.join('/')
  end

  ##
  # Creates a session to use the same `uuid`.  Supply your own `uuid`
  # with optional parameter or one will be generated for you.
  #
  # When providing a block, the session will be automatically cleared.
  # Otherwise, you must manually `clear!` the session when it is finished.
  #
  # See
  # clear!

  def use id=generate
    self.custom_id = id

    if block_given?
      yield custom_id
      clear!
    else
      custom_id
    end
  end

  ##
  # Manually clears the session using the same `uuid`

  def clear!
    @custom_id = nil
  end

  ##
  # Returns the `uuid` in a session or generates a new `uuid`
  #
  # See
  # generate

  def current
    custom_id || @request_id = generate
  end
  alias_method :to_s, :current

  ##
  # Returns the previously generated or session `uuid`
  #
  # See
  # current

  def previous
    @request_id ||= current
  end

  def inspect
    "\"#{current}\""
  end
end