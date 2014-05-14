module Organ
  module Coercer

    # Coerce the value into a String or nil if no value given.
    #
    # @param value [Object]
    # @option options [Boolan] :trim (false)
    #   If true, it strips the preceding/trailing whitespaces and newlines.
    #   It also replaces multiple consecutive spaces into one.
    #
    # @return [String, nil]
    #
    # @api semipublic
    def coerce_string(value, options = {})
      value = value ? value.to_s : nil
      if value && options[:trim]
        value = value.strip.gsub(/\s{2,}/, " ")
      end
      value
    end

    # Corce the value into true or false.
    #
    # @param value [Object]
    #
    # @return [Boolean]
    #
    # @api semipublic
    def coerce_boolean(value, options = {})
      !!value
    end

    # Coerce the value into an Array.
    #
    # @param value [Object]
    #   The value to be coerced.
    # @option options [Symbol] :element_type (nil)
    #   The type of the value to coerce each element of the array. No coercion
    #   done if type is nil.
    #
    # @return [Array]
    #   The coerced Array.
    #
    # @api semipublic
    def coerce_array(value, options = {})
      element_type = options[:element_type]
      value = value.values if value.kind_of?(Hash)
      if value.kind_of?(Array)
        if element_type
          value.map do |array_element|
            send("coerce_#{element_type}", array_element)
          end
        else
          value
        end
      else
        []
      end
    end

    # Coerce the value into a Float.
    #
    # @param value [Object]
    #
    # @return [Float, nil]
    #
    # @api semipublic
    def coerce_float(value, options = {})
      Float(value) rescue nil
    end

    # Coerce the value into a Hash.
    #
    # @param value [Object]
    #   The value to be coerced.
    # @option options :key_type [Symbol] (nil)
    #   The type of the hash keys to coerce, no coersion done if type is nil.
    # @options options :value_type [Symbol] (nil)
    #   The type of the hash values to coerce, no coersion done if type is nil.
    #
    # @return [Hash]
    #   The coerced Hash.
    #
    # @api semipublic
    def coerce_hash(value, options = {})
      key_type = options[:key_type]
      value_type = options[:value_type]
      if value.kind_of?(Hash)
        value.each_with_object({}) do |(key, value), coerced_hash|
          key = send("coerce_#{key_type}", key) if key_type
          value = send("coerce_#{value_type}", value) if value_type
          coerced_hash[key] = value
        end
      else
        {}
      end
    end

    # Coerce the value into an Integer.
    #
    # @param value [Object]
    #   The value to be coerced.
    #
    # @return [Integer, nil]
    #   An Integer if the value can be coerced or nil otherwise.
    #
    # @api semipublic
    def coerce_integer(value, options = {})
      value = value.to_s
      if value.match(/\A0|[1-9]\d*\z/)
        value.to_i
      else
        nil
      end
    end

    # Coerce the value into a Date.
    #
    # @param value [Object]
    #   The value to be coerced.
    #
    # @return [Date, nil]
    #   A Date if the value can be coerced or nil otherwise.
    #
    # @api semipublic
    def coerce_date(value, options = {})
      value = coerce(value, String)
      begin
        Date.strptime(value, "%Y-%m-%d")
      rescue ArgumentError
        nil
      end
    end

  end
end
