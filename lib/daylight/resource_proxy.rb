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
    @current_params    = {}
    @association_name, @association_resource = association.first
  end

  def << value
    if association_resource
      elements = association_resource.new? ? [] : records.elements
      association_resource.send("#{association_name}=", elements << value)
    else
      raise NoMethodError, "undefined method `<<' for #{self}"
    end
  end

  def from from
    @from = from
    self
  end

  def load
    resource_class.find(:all, params: to_params, from: @from)
  end

  def to_params
    current_params.dup
  end

  def records
    @records ||= load
  end

  def reload
    @records = load
  end

  def to_a
    records.to_a
  end

  def append_scope scope
    current_params[:scopes] ||= []
    current_params[:scopes] << scope
    current_params[:scopes].uniq!
    self
  end

  def where conditions
    current_params[:filters] ||= {}
    current_params[:filters].merge! conditions
    self
  end

  def find_by conditions
    where(conditions).limit(1).first
  end

  def limit value
    current_params[:limit] = value
    self
  end

  def order value
    current_params[:order] = value
    self
  end

  def offset value
    current_params[:offset] = value
    self
  end

  def first
    limit(1).to_a.first
  end

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
    #
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

  def method_missing(method_name, *args, &block)
    if resource_class.respond_to?(method_name)
      self.class.send(:define_method, method_name) do |*method_args, &method_block|
        resource_class.send(method_name, *method_args, &method_block)
      end
      resource_class.send(method_name, *args, &block)
    elsif Array.method_defined?(method_name)
      self.class.delegate method_name, :to => :to_a
      to_a.send(method_name, *args, &block)
    else
      super
    end
  end

  private
    attr_accessor :current_params
end
