Feature: NotBlank constraint

  `not_blank` constraint guarantees presence of a non empty value

  Background: NotBlank validator
    Given a file named "validator.rb" with:
      """ruby
      require 'validate'

      Validate::Validators.define(:value) do
        not_blank(message: '%{value.inspect} must not be blank')
      end
      """

  Scenario: Values are invalid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(nil, as: :value)
      puts Validate.validate('', as: :value)
      puts Validate.validate([], as: :value)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      nil must not be blank
      "" must not be blank
      [] must not be blank
      """

  Scenario: Values are valid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate('a valid value', as: :value)
      puts Validate.validate(['qwe'], as: :value)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
