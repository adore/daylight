##
# Handles X-Request-Id functionality the same as `ActionDispatch::RequestId`
# but allows the value to include more characters: alphanumereric,
# and `-`, `\`, `+`, `=`.
#
# See
# ActionDispatch::RequestId
module Daylight::RequestId < ActionDispatch::RequestId
  private
    def external_request_id(env)
      if request_id = env["HTTP_X_REQUEST_ID"].presence
        request_id.gsub(/[^\w\/\-+=]/, "").first(255)
      end
    end
end

# Require server to support X-Request-Id
ActiveSupport.on_load :before_initialize do
  config.middleware.insert_after(ActionDispatch::Static, Daylight::RequestId)
end
