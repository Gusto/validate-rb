# frozen_string_literal: true

module Validate
  module Validators
    module DSL
      include Arguments

      arg(:name) { is_a(Module) | (is_a(Symbol) & not_blank) }
      def define(name, &body)
        Scope.current.register_validator(name, create(&body))
      end

      def create(&block)
        Validator.new(&block)
      end

      def none
        @none ||= Validator::None.new
      end
    end

    class Validator
      def initialize(&block)
        @constraints = AST::DefinitionContext.create(&block)
      end

      def validate(ctx)
        @constraints.evaluate(ctx)
      end

      private

      class None < Validator
        NO_VIOLATIONS = [].freeze

        def initialize; end

        def validate(*args)
          NO_VIOLATIONS
        end
      end
    end
  end
end
