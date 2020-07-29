# frozen_string_literal: true

module Validate
  module Error
    class StandardError < ::StandardError
      include Error
    end

    class ArgumentError < ::ArgumentError
      include Error
    end

    class KeyError < ::KeyError
      include Error
    end

    class IndexError < ::IndexError
      include Error
    end

    class ValidationRuleError < StandardError
    end

    class ConstraintViolationError < StandardError
      attr_reader :violations

      def initialize(violations)
        @violations = violations
        super()
      end

      def message
        @violations.group_by(&:path)
                   .transform_values { |violations| violations.map(&:message) }
                   .map { |path, messages| "#{path}: #{messages.join(', ')}" }
                   .join("\n")
      end
    end
  end
end
