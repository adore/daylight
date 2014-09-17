# Require server to support X-Request-Id
if defined?(ActionDispatch::Static) && defined?(ActionDispatch::RequestId)
  ActiveSupport.on_load :before_initialize do
    config.middleware.insert_after(ActionDispatch::Static, ActionDispatch::RequestId)
  end
end
