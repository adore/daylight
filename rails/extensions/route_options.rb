##
# Support for :associated and :methods options on resource routes
#
# :associated specifies which assocations are supported by the resource
# :remoted    specifies which remote methods are supported by the resource
module RouteOptions
  extend ActiveSupport::Concern

  included do
    def set_member_mappings_for_resource
      super

      associated = parent_resource.options[:associated] || []
      remoted    = parent_resource.options[:remoted]    || []

      member do
        associated.each do |association|
          get association, to: "#{parent_resource.plural}#associated", defaults: {associated: association}, as: association
        end

        remoted_model = get_remoted_model
        remoted.each do |remote|
          remoted_model.add_remoted(remote) if remoted_model
          get remote, to: "#{parent_resource.name}#remoted", defaults: {remoted: remote}, as: remote
        end

      end

    end

    private

      def get_remoted_model
        controller = "#{parent_resource.name}_controller".classify.constantize rescue nil
        controller && controller.respond_to?(:model) ? controller.send(:model) : parent_resource.name.classify.constantize
      rescue
        Rails.logger.warn "Could not lookup model for #{parent_resource.name} to apply remoted."
      end

  end
end

ActionDispatch::Routing::Mapper.class_eval do
  include RouteOptions

  # need to support the associated and :remoted resource options
  self::Resources::RESOURCE_OPTIONS << :associated
  self::Resources::RESOURCE_OPTIONS << :remoted
end
