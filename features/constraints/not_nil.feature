Feature: NotNil constraint

  `not_nil` constraint guarantees presence of value

  Background: NotNil validator
    Given a file named "validator.rb" with:
      """ruby
      require 'validate'

      Validate::Validators.define(:not_nil) do
        not_nil(message: '%{value.inspect} must not be nil')
      end
      """

  Scenario: Value is nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(nil, as: :not_nil)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      nil must not be nil
      """

  Scenario: Value is not nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(true, as: :not_nil)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
