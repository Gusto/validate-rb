Feature: Validate constraint

  `validate` constraint evaluates object using a block

  Background: Validate validator
    Given a file named "validator.rb" with:
      """ruby
      require 'validate'

      Validate::Validators.define(:odd_number) do
        validate(message: '%{value.inspect} must be odd') do |value|
          value % 2 == 1
        end
      end

      Validate::Validators.define(:even_number) do
        validate(message: '%{value.inspect} must be even') do |value|
          value % 2 == 0
        end
      end
      """

  Scenario: Values are invalid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(2, as: :odd_number)
      puts Validate.validate(1, as: :even_number)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      2 must be odd
      1 must be even
      """

  Scenario: Values are nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(nil, as: :odd_number)
      puts Validate.validate(nil, as: :even_number)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: Values are valid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(1, as: :odd_number)
      puts Validate.validate(2, as: :even_number)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
