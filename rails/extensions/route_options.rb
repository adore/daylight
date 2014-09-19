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
      scopes     = parent_resource.options[:scopes]     || []

      model_class = controller_model_class
      model_class.whitelist_scopes(*scopes) if scopes.present?

      member do
        associated.each do |association|
          get association, to: "#{parent_resource.plural}#associated", defaults: {associated: association}, as: association
        end

        remoted.each do |remote|
          model_class.add_remoted(remote) if model_class
          get remote, to: "#{parent_resource.name}#remoted", defaults: {remoted: remote}, as: remote
        end
      end

    end

    private

      def controller_model_class
        controller = "#{parent_resource.name}_controller".classify.constantize rescue nil
        controller && controller.respond_to?(:model) ? controller.send(:model) : parent_resource.name.classify.constantize
      rescue
        Rails.logger.warn "Could not lookup model for #{parent_resource.name} to apply remoted."
      end

  end
end

ActionDispatch::Routing::Mapper.class_eval do
  include RouteOptions

  # need to support the associated, remoted and scopes resource options
  self::Resources::RESOURCE_OPTIONS << :associated
  self::Resources::RESOURCE_OPTIONS << :remoted
  self::Resources::RESOURCE_OPTIONS << :scopes
end
