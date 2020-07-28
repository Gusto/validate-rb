Feature: Contain constraint

  `contain` constraint checks that a string is contained within another string

  Background: Contain validator
    Given a file named "validator.rb" with:
      """ruby
      require 'uri'

      require 'validate'

      Validate::Validators.define(:negation) do
        contain('not', message: '%{value.inspect} must have "not"')
      end
      """

  Scenario: Values are invalid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate('this will fail', as: :negation)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      "this will fail" must have "not"
      """

  Scenario: Values are nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(nil, as: :negation)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: Values are valid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate('this will not fail', as: :negation)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
