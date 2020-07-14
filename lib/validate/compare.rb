# frozen_string_literal: true

module Validate
  module Compare
    class ByAttributes
      include Comparable

      def initialize(attributes)
        @attributes = attributes
      end

      def <=>(other)
        @attributes.map { |attribute, value| value <=> other.send(attribute) }
                   .find { |result| !result.zero? } || 0
      end

      def method_missing(symbol, *args)
        return super unless args.empty? && respond_to_missing?(symbol)

        @attributes[symbol]
      end

      def respond_to_missing?(attribute, _ = false)
        @attributes.include?(attribute)
      end
    end

    module_function

    def attributes(**attributes)
      ByAttributes.new(attributes)
    end
  end
end
