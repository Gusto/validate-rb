# typed: strict
# frozen_string_literal: true

module Validate
  module Assertions
    module_function

    def create(*args, &block)
      Assertion.new(AST::DefinitionContext.create(*args, &block))
    end

    class Assertion
      def initialize(validation_context)
        @constraints = validation_context
      end

      def assert(value, error_class: Error::ArgumentError, message: 'invalid value')
        ctx = Constraints::ValidationContext.root(value)
        @constraints.evaluate(ctx)
        return value unless ctx.has_violations?

        raise error_class, message,
              cause: ctx.to_err
      end
    end
  end
end
