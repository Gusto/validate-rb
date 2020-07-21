# frozen_string_literal: true

module Validate
  module Compare
    class WithAttributes
      include Comparable
      prepend UsingTransformation

      def initialize(attributes)
        @attributes = attributes
      end

      def <=>(other)
        @attributes.map { |attribute, value| value <=> other.send(attribute) }
                   .find { |result| !result.zero? } || 0
      end
    end

    class ToValue
      include Comparable
      prepend UsingTransformation

      def initialize(value_block)
        @value_block = value_block
      end

      def <=>(other)
        @value_block.call <=> other
      end
    end

    module UsingTransformation
      def using(&transform_block)
        @transform_block = transform_block
        self
      end

      def <=>(other)
        return super if @transform_block.nil?

        super(@transform_block.call(other))
      end
    end

    module_function

    def attributes(**attributes)
      WithAttributes.new(attributes)
    end

    def to(value = nil, &value_block)
      value_block ||= value.is_a?(Proc) ? value : proc { value }
      ToValue.new(value_block)
    end
  end
end
