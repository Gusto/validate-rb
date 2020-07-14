Feature: NotEmpty constraint

  `not_empty` constraint guarantees that value is not empty but does not guarantee its presence

  Background: NotEmpty validator
    Given a file named "validator.rb" with:
      """ruby
      require 'validate'

      Validate::Validators.define(:not_empty) do
        not_empty(message: '%{value.inspect} must not be empty')
      end
      """

  Scenario: Values are invalid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate([], as: :not_empty)
      puts Validate.validate('', as: :not_empty)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      [] must not be empty
      "" must not be empty
      """

  Scenario: Value is valid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(['qwe'], as: :not_empty)
      puts Validate.validate('qwe', as: :not_empty)
      puts Validate.validate(nil, as: :not_empty)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
