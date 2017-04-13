module Organ
  module Validations

    EMAIL_FORMAT = /\A
      ([0-9a-zA-Z\.][-\w\+\.]*)@
      ([0-9a-zA-Z_][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,9}\z/x

    # Get the current form errors Hash.
    #
    # @return [Hash<Symbol, Array<Symbol>]
    #   The errors Hash, having the Symbol attribute names as keys and an
    #   array of errors (Symbols) as the value.
    #
    # @api public
    def errors
      @errors ||= Hash.new { |hash, key| hash[key] = [] }
    end

    # Determine if current form instance is valid by running the validations
    # specified on #validate.
    #
    # @return [Boolean]
    #
    # @api public
    def valid?
      errors.clear
      validate
      errors.empty?
    end

    # Append an error to the given attribute.
    #
    # @param attribute_name [Symbol]
    # @param error [Symbol]
    #   The error identifier.
    #
    # @api public
    def append_error(attribute_name, error)
      errors[attribute_name] << error
    end

    # Call the given block if there are no errors.
    #
    # @param block [Proc]
    #
    # @api public
    def validation_block(&block)
      block.call if errors.empty?
    end

    # Validate the presence of the attribute value. If the value is nil or
    # false append a :blank error to the attribute.
    #
    # @param attribute_name [Symbol]
    #
    # @api public
    def validate_presence(attribute_name)
      value = send(attribute_name)
      unless present?(value)
        append_error(attribute_name, :blank)
      end
    end

    # Validate the uniqueness of the attribute value (if present). The
    # uniqueness is determined by the block given. If the value is not unique,
    # append the :taken error to the attribute.
    #
    # @param attribute_name [Symbol]
    # @param block [Proc]
    #   A block to determine if a given value is unique or not. It receives
    #   the value and should return true if the value is unique.
    #
    # @api public
    def validate_uniqueness(attribute_name, &block)
      value = send(attribute_name)
      if present?(value) && !block.call(value)
        append_error(attribute_name, :taken)
      end
    end

    # Validate the email format (if present). If the value does not match the
    # email format, append the :invalid error to the attribute.
    #
    # @param attribute_name [Symbol]
    #
    # @api public
    def validate_email_format(attribute_name)
      validate_format(attribute_name, EMAIL_FORMAT)
    end

    # Validate the format of the attribute value (if present). If the value does
    # not match the regexp given, append :invalid error to the attribute.
    #
    # @param attribute_name [Symbol]
    # @param format [Regexp]
    #
    # @api public
    def validate_format(attribute_name, format)
      value = send(attribute_name)
      if present?(value) && !(format =~ value)
        append_error(attribute_name, :invalid)
      end
    end

    # Validate the length of a String, Array or any other form attribute which
    # responds to #size (if present). If the value is too short, append the
    # :too_short error to the attribute. If the value is too long append the
    # :too_long error to the attribute.
    #
    # @param attribute_name [Symbol]
    # @option options [Integer, nil] :min (nil)
    # @option options [Integer, nil] :max (nil)
    #
    # @api public
    def validate_length(attribute_name, options = {})
      min = options.fetch(:min, nil)
      max = options.fetch(:max, nil)
      value = send(attribute_name)

      if present?(value)
        length = value.size
        if min && length < min
          append_error(attribute_name, :too_short)
        end
        if max && length > max
          append_error(attribute_name, :too_long)
        end
      end
    end

    # Validate the value of the given attribute is included in the list (if
    # present). If the value is not included in the list, append the
    # :not_included error to the attribute.
    #
    # @param attribute_name [Symbol]
    # @param attribute_name [Symbol]
    # @param list [Array]
    #
    # @api public
    def validate_inclusion(attribute_name, list)
      value = send(attribute_name)
      if present?(value) && !list.include?(value)
        append_error(attribute_name, :not_included)
      end
    end

    # Validate the range in which the attribute can be (if present). If the
    # value is less than the min a :less_than_min error will be appended. If the
    # value is greater than the max a :greater_than_max error will be appended.
    #
    # @param attribute_name [Symbol]
    # @option options [Integer] :min (nil)
    #   The minimum value the attribute can take, if nil, no validation is made.
    # @option options [Integer] :max (nil)
    #   The maximum value the attribute can take, if nil, no validation is made.
    #
    # @api public
    def validate_range(attribute_name, options = {})
      value = send(attribute_name)

      return unless present?(value)

      min = options.fetch(:min, nil)
      max = options.fetch(:max, nil)
      append_error(attribute_name, :less_than) if min && value < min
      append_error(attribute_name, :greater_than) if max && value > max
    end

    # Determine if the value is present (not nil, false or an empty string).
    #
    # @param value [Object]
    #
    # @return [Boolean]
    #
    # @api private
    def present?(value)
      value && !value.to_s.empty?
    end

  end
end
