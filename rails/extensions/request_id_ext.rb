##
# Handles X-Request-Id functionality patching `ActionDispatch::RequestId`
# to allows the header value to include more characters than alphanumereric
# and `-`.  Extends it to also allow: `\`, `+`, `=`.
#
# See
# ActionDispatch::RequestId

module Daylight::RequestIdExt
  private
    def external_request_id(env)
      if request_id = env["HTTP_X_REQUEST_ID"].presence
        request_id.gsub(/[^\w\/\-+=]/, "").first(255)
      end
    end
end

# Mix into ActionDispatch::RequestId
ActiveSupport.on_load :before_initialize do
  ActionDispatch::RequestId.send(:prepend, Daylight::RequestIdExt)
end
