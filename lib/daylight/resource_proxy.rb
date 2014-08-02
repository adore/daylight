##
# Proxies requests to ActiveResource once the data has been accessed.
# Allows chaining of scope calls ala ActiveRecord
class Daylight::ResourceProxy
  include Enumerable

  delegate :to_xml, :to_yaml, :length, :each, :to_ary, :size, :last, :[], :==, to: :to_a
  delegate :first_or_initialize, :first_or_create, to: :records
  delegate :resource_class, to: :class

  attr_reader :association_name, :association_resource

  # turn off constructor, only use factory methods
  private_class_method :new

  def initialize association={}
    @current_params = {}
    @association_name, @association_resource = association.first
  end

  ##
  # Sets `from` URL on a request
  def from from
    @from = from
    self
  end

  ##
  # Loads records from server based on current paremeters and from URL
  def load
    resource_class.find(:all, params: to_params, from: @from).tap do |results|
      @original_result_ids = results.map(&:id)
    end
  end

  ##
  # Returns a copy of the current parameters used to fetch records
  def to_params
    current_params.dup
  end

  ##
  # Returns the records, requests them from server if not fetched
  def records
    @records ||= load
  end

  ##
  # Returns the records, forces fetch from server
  def reload
    @records = load
  end

  ##
  # Converts records to an Array
  def to_a
    records.to_a
  end

  ##
  # Adds scopes to the current parameters
  def append_scope scope
    spawn.tap do |proxy|
      proxy.current_params[:scopes] ||= []
      proxy.current_params[:scopes] << scope
      proxy.current_params[:scopes].uniq!
    end
  end

  ##
  # Merges conditions to the current parameters
  def where conditions
    spawn.tap do |proxy|
      proxy.current_params[:filters] ||= {}
      proxy.current_params[:filters].merge! conditions
    end
  end

  ##
  # Sets limit in the current parameters
  def limit value
    spawn.tap do |proxy|
      proxy.current_params[:limit] = value
    end
  end

  ##
  # Sets order in the current parameters
  def order value
    spawn.tap do |proxy|
      proxy.current_params[:order] = value
    end
  end

  ##
  # Sets offset in the current parameters
  def offset value
    spawn.tap do |proxy|
      proxy.current_params[:offset] = value
    end
  end

  ##
  # Merges conditions to the current parameters, and fetches the first result.
  # Immediately issues the request to the API.

  def find_by conditions
    where(conditions).limit(1).first
  end

  ##
  # Sets the limit to the current parameters, and fetches the first result.
  # Immediately issues the request to the API.

  def first
    limit(1).to_a.first
  end

  ##
  # Special inspect that shows the fetched results (up to 10 fo them) and the
  # current params to fetch those results.
  #
  # Immediately issues the request to the API.

  def inspect
    records = to_a.take(11)
    records[10] = '...' if entries.size == 11

    "#<#{self.class.name} #{records} @current_params=#{current_params}>"
  end

  class << self
    # Each ResourceProxy will have thier own resource
    attr_accessor :resource_class

    ##
    # Factory method to generate a child class for ResourceProxy with the
    # required resource class.
    #
    #     proxy = ResourceProxy[User]  #=> User::ResourceProxy
    #
    # Onece a child class has been created, it can be use it to create
    # instances:
    #
    #    ResourceProxy[User].new

    def [] resource_class
      if resource_class.const_defined?(:ResourceProxy)
        return resource_class.const_get(:ResourceProxy)
      end

      Class.new(Daylight::ResourceProxy) do
        # Allow instances to be created
        public_class_method :new

        # Set our resource
        self.resource_class = resource_class

        # Set our ResourceProxy constant
        resource_class.const_set(:ResourceProxy, self)
      end
    end

    ##
    # Define a name for the class
    def name
      "#{resource_class}::ResourceProxy"
    end

    ##
    # Use the class name as the inspect
    alias_method :inspect, :name
  end

  ##
  # Will attempt to fulfill the method if it exists on the resource or if it
  # exists on an Array.  Delegates the method on for subsequent execution.

  def method_missing(method_name, *args, &block)
    if resource_class.respond_to?(method_name)
      self.class.send(:define_method, method_name) do |*method_args, &method_block|
        resource_class.send(method_name, *method_args, &method_block)
      end
      resource_class.send(method_name, *args, &block)
    elsif Array.method_defined?(method_name)
      array = to_a
      count_before = array.count
      response = array.send(method_name, *args, &block)
      # update the association if the array has changed
      association_resource.send("#{association_name}=", array) if association_name && count_before != array.count
      response
    else
      super
    end
  end

  protected
    attr_accessor :current_params

    ##
    # Clone current ResourceProxy and with `current_params` to keep its query
    # context
    #
    # See
    # reset

    def spawn
      clone.reset(current_params)
    end

    ##
    # Resets a ResourceProxy marked to refetch results based on blank or
    # supplied `current_params`

    def reset old_params={}
      @current_params = old_params.deep_dup
      @records = nil
      self
    end
end
