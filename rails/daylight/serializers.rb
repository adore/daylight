ActiveSupport.on_load(:after_initialize) do

  Rails.application.eager_load!

  ActiveRecord::Base.descendants.each do |model_class|
    serializer = model_class.respond_to?(:active_model_serializer) && model_class.active_model_serializer rescue nil
    if serializer.nil?
      klass = Class.new(ActiveModel::Serializer)
      klass.class_eval do
        embed :ids
        attributes :id
      end
      Object.const_set "#{model_class.name}Serializer", klass
    end
  end

end
