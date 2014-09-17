# Require server to support X-Request-Id
if defined?(ActionDispatch::RequestId)
  ActiveSupport.on_load :before_initialize do
    config.middleware.insert_before(::Rack::Lock, ActionDispatch::RequestId)
  end
end