require_relative "validation_error"
require_relative "validations"
require_relative "coercer"

module Organ
  # Form for doing actions based on the attributes specified.
  # This class has to be inherited by different forms, each performing a
  # different action. If validations are needed, #validate method should be
  # overridden.
  #
  # @example
  #
  #   class LoginForm < Organ::Form
  #
  #     attribute(:username, :type => :string)
  #     attribute(:password, :type => :string)
  #
  #     def validate
  #       unless valid_login?
  #         append_error(:username, :invalid)
  #       end
  #     end
  #
  #     private
  #
  #     def valid_login?
  #       user = User.where(username: username).first
  #       user && check_password_secure(user.password, password)
  #     end
  #
  #   end
  #
  class Form

    include Organ::Validations
    include Organ::Coercer

    # Copy parent attributes to inherited class.
    #
    # @param klass [Class]
    #
    # @api private
    def self.inherited(klass)
      super(klass)
      klass.instance_variable_set(:@attributes, attributes.dup)
    end

    # Define an attribute for the form.
    #
    # @param name
    #   The Symbol attribute name.
    # @option options [Symbol] :type (nil)
    #   The type of this attribute.
    # @option options [Symbol] :skip_reader (false)
    #   If true, skips from creating the attribute reader.
    #
    # @api public
    def self.attribute(name, options = {})
      attr_reader(name) unless options[:skip_reader]
      define_method("#{name}=") do |value|
        if options[:type]
          value = send("coerce_#{options[:type]}", value, options)
        end
        instance_variable_set("@#{name}", value)
      end
      attributes[name] = options
    end

    # Retrieve the list of attributes of the form.
    #
    # @return [Hash]
    #   The class attributes hash.
    #
    # @api private
    def self.attributes
      @attributes ||= {}
    end

    # Initialize a new Form::Base form.
    #
    # @param attrs [Hash]
    #   The attributes values to use for the new instance.
    #
    # @api public
    def initialize(attrs = {})
      set_attributes(attrs)
    end

    # Set the attributes belonging to the form.
    #
    # @param attrs [Hash<String, Object>]
    #
    # @api public
    def set_attributes(attrs)
      return unless attrs.kind_of?(Hash)

      attrs = coerce_hash(attrs, :key_type => :string)

      self.class.attributes.each do |attribute_name, _|
        send("#{attribute_name}=", attrs[attribute_name.to_s])
      end
    end

    # Get the all attributes with its values of the current form.
    #
    # @return [Hash<Symbol, Object>]
    #
    # @api public
    def attributes
      self.class.attributes.each_with_object({}) do |(name, opts), attrs|
        attrs[name] = send(name) unless opts[:skip]
      end
    end

    # Validate and perform the form actions. If any errors come up during the
    # validation or the #perform method, raise an exception with the errors.
    #
    # @raise [Organ::ValidationError]
    #
    # @api public
    def perform!
      if valid?
        perform
      end
      if errors.any?
        raise Organ::ValidationError.new(errors)
      end
    end

  end
end
