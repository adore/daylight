module API
  extend ActiveSupport::Autoload

  module V1
    extend ActiveSupport::Autoload

    autoload :Blog
    autoload :Comment
    autoload :Company
    autoload :Post
    autoload :User
  end

end
