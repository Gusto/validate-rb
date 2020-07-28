Feature: StartWith constraint

  `start_with` constraint checks string's prefix

  Background: StartWith validator
    Given a file named "validator.rb" with:
      """ruby
      require 'uri'

      require 'validate'

      Validate::Validators.define(:negative_statement) do
        start_with('no but ', message: '%{value.inspect} must be negative')
      end

      Validate::Validators.define(:positive_statement) do
        start_with('yes and ', message: '%{value.inspect} must be positive')
      end
      """

  Scenario: Values are invalid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate('no but could do something else', as: :positive_statement)
      puts Validate.validate('yes and we could do something else', as: :negative_statement)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      "no but could do something else" must be positive
      "yes and we could do something else" must be negative
      """

  Scenario: Values are nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(nil, as: :positive_statement)
      puts Validate.validate(nil, as: :negative_statement)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: Values are valid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate('yes and we could do something else', as: :positive_statement)
      puts Validate.validate('no but could do something else', as: :negative_statement)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
