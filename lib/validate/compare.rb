# frozen_string_literal: true

module Validate
  module Compare
    module TransformUsing
      def using(&transform_block)
        @transform_block = transform_block
        self
      end

      def <=>(other)
        return super if @transform_block.nil?

        super(@transform_block.call(other))
      end
    end

    class WithAttributes
      include Comparable
      prepend TransformUsing

      def initialize(attributes)
        @attributes = attributes
      end

      def <=>(other)
        @attributes.each do |attribute, value|
          result = value <=> other.send(attribute)
          return result unless result.zero?
        end

        0
      end

      def method_missing(symbol, *args)
        return super unless args.empty? && respond_to_missing?(symbol)

        @attributes[symbol]
      end

      def respond_to_missing?(attribute, _ = false)
        @attributes.include?(attribute)
      end

      def to_s
        '<attributes ' + @attributes.map { |attribute, value| "#{attribute}: #{value}"}
                                    .join(', ') + '>'
      end
    end

    class ToValue
      include Comparable
      prepend TransformUsing

      def initialize(value_block)
        @value_block = value_block
      end

      def <=>(other)
        @value_block.call <=> other
      end

      def to_s
        '<dynamic value>'
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
