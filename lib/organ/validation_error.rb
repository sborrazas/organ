module Organ
  class ValidationError < StandardError

    # !@attribute [r] errors
    #   @return [Hash<Symbol, Array>]
    #
    # @api public
    attr_reader :errors

    # Initialize the Organ::ValidationError.
    #
    # @param errors [Hash<Symbol, Array>]
    #
    # @api public
    def initialize(errors)
      @errors = errors
    end

  end
end
