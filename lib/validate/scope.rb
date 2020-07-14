# typed: strict
# frozen_string_literal: true

module Validate
  class Scope
    def self.current
      @current ||= Scope.new
    end

    def initialize
      @constraints = {}
      @validators = {}
    end

    def register_validator(name, validator)
      if @validators.include?(name)
        raise Error::ArgumentError,
              "duplicate validator :#{name}"
      end

      @validators[name] = validator
    end

    def validator?(name)
      @validators.include?(name)
    end

    def validator(name)
      validator_name.assert(name,
                            message: "invalid validator #{name.inspect}",
                            error_class: KeyError)

      @validators.fetch(name) { name.validator }
    end

    private

    def validator_name
      @validator_name ||= Assertions.create(@validators) do |validators|
        not_nil(message: 'name must not be nil')
        (one_of(values: validators,
                message: '%{value.inspect} must be an existing validator name') |
            respond_to(:validator,
                       message: '%{value.inspect} must respond to :validator'))
      end
    end
  end
end
