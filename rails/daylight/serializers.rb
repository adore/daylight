module Daylight::Serializers

  ##
  # Define a fallback serializer

  def active_model_serializer
    super || auto_generate_serializer
  end

  private

    ##
    # Create a simple serializer that sends all attributes and has_one and belongs_to associations

    def auto_generate_serializer
      model_clazz = self.class
      @auto_generated_serializer ||=
        Class.new(ActiveModel::Serializer) do
          embed :ids
          attributes(*model_clazz.column_names.map(&:to_sym))
          model_clazz.reflections.each_pair do |name, reflection|
            options = reflection.options
            case reflection.macro
            when :has_one, :belongs_to
              has_one name, key: options[:foreign_key], through: options[:through]
            end
          end

          # ActiveModelSerializer's model_class uses the serializer's class name to
          # determine the model's class. Since this is an anonymous class and has
          # no name, we have to override this.
          singleton_class.class_eval do
            define_method :model_class do
              model_clazz
            end
          end
        end
    end

end

# Mix into ActiveRecord::Base
ActiveSupport.on_load :active_record do
  include Daylight::Serializers
end
