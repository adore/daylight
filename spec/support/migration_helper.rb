module MigrationHelper
  extend ActiveSupport::Concern

  module ClassMethods
    attr_accessor :migrations

    def migrate &block
      migrations << Class.new(ActiveRecord::Migration) do
        define_method :change, &block
      end
    end

    def migrations
      @migrations ||= []
    end
  end

  included do
    before(:all) do
      self.class.migrations.each do |migration|
       ActiveRecord::Migration.suppress_messages do
         migration.migrate(:up)
       end
      end
    end

    after(:all) do
      self.class.migrations.each do |migration|
        ActiveRecord::Migration.suppress_messages do
          migration.migrate(:down)
        end
      end
    end
  end

end

RSpec.configure do |config|
  config.include MigrationHelper
end