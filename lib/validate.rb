# frozen_string_literal: true

require 'forwardable'
require 'monitor'

require_relative 'validate/version'
require_relative 'validate/errors'
require_relative 'validate/constraint'
require_relative 'validate/assertions'
require_relative 'validate/arguments'
require_relative 'validate/ast'
require_relative 'validate/scope'
require_relative 'validate/helpers'
require_relative 'validate/constraints/validation_context'
require_relative 'validate/constraints'
require_relative 'validate/validators/dsl'
require_relative 'validate/validators'
require_relative 'validate/compare'

# Validate.rb can be used independently by calling {Validate.validate}
# or included in classes and modules.
#
# @example Validating an object using externally defined metadata
#   Address = Struct.new(:street, :city, :state, :zip)
#   Validate::Validators.define(Address) do
#     attr(:street) { not_blank }
#     attr(:city) { not_blank }
#     attr(:state) { not_blank & length(2) }
#     attr(:zip) { not_blank & match(/[0-9]{5}(\-[0-9]{4})?/) }
#   end
#   puts Validate.validate(Address.new)
#
# @example Validating an object using metdata defined in class
#   class Address < Struct.new(:street, :city, :state, :zip)
#     include Validate
#     validate do
#       attr(:street) { not_blank }
#       attr(:city) { not_blank }
#       attr(:state) { not_blank & length(2) }
#       attr(:zip) { not_blank & match(/[0-9]{5}(\-[0-9]{4})?/) }
#     end
#   end
#   puts Validate.validate(Address.new)
module Validate
  # Validate an object and get constraint violations list back
  #
  # @param object [Object] object to validate
  # @param as [Symbol, Class] (object.class) validator to use, defaults to
  #   object's class
  #
  # @return [Array<Constraint::Violation>] list of constraint violations
  def self.validate(object, as: object.class)
    violations = []
    Scope.current
         .validator(as)
         .validate(Constraints::ValidationContext.root(object, violations))
    violations.freeze
  end

  # Check if a given validator exists
  #
  # @param name [Symbol, Class] validator to check
  #
  # @return [Boolean] `true` if validator is present, `else` otherwise
  def self.validator?(name)
    Scope.current.validator?(name)
  end

  # Hook to allow for inclusion in class or module
  def self.included(base)
    base.extend(ClassMethods)
  end

  # @private
  module ClassMethods
    def validator(&body)
      @validator ||= Validators.create(&body)
    end
  end
end
