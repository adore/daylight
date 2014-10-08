##
# Helper methods for rendering the endpoint/model documentation.
module DaylightDocumentation::DocumentationHelper

  ACTION_DEFINITIONS = {
    'index'      => "Retrieves a list of %{names}",
    'create'     => "Creates a new %{name}",
    'show'       => "Retrieves a %{name} by an ID",
    'update'     => "Updates a %{name}",
    'associated' => "Returns %{name}\'s %{associated}",
    'remoted'    => "Calls %{name}\'s remote method %{remoted}"
  }

  ##
  # Yield all of the route information for the given model.
  #
  # Yields route verb (GET, POST, etc), path specification, route defaults
  def model_verbs_and_routes(model)
    routes = Rails.application.routes.routes.select {|route| route.path.spec.to_s.include? "/#{model.name.underscore.pluralize}" }

    routes.each do |route|
      yield route_verb(route), route.path.spec, route.defaults
    end
  end

  ##
  # A list of all the possible filters for the given model.
  def model_filters(model)
    model.attribute_names + model.reflection_names
  end

  ##
  # A description of a route given the route defaults and model class.
  def action_definition(defaults, model)
    ACTION_DEFINITIONS[defaults[:action]] % {
      name:       model.name.titleize.downcase,
      names:      model.name.titleize.pluralize.downcase,
      associated: defaults[:associated].to_s.pluralize.tr('_', ' '),
      remoted:    defaults[:remoted]
    }
  end

  def client_namespace
    Daylight::Documentation.namespace
  end

  def api_version
    Daylight::Documentation.version.downcase
  end

  private

    def route_verb(route)
      %w[GET POST PUT PATCH DELETE].find {|verb| verb =~ route.verb}
    end

end
