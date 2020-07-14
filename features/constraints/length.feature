Feature: Length constraint

  `length` constraint guarantees object's length is within bounds

  Background: Length validator
    Given a file named "validator.rb" with:
      """ruby
      require 'validate'

      Validate::Validators.define(:min_length) do
        length(min: 3, message: '%{value.inspect} must have length of at least %{constraint.min}')
      end

      Validate::Validators.define(:max_length) do
        length(max: 5, message: '%{value.inspect} must have length of at most %{constraint.max}')
      end

      Validate::Validators.define(:between_length) do
        length(3..5, message: '%{value.inspect} must have length between %{constraint.min} and %{constraint.max}')
      end

      Validate::Validators.define(:exact_length) do
        length(4, message: '%{value.inspect} must have length of %{constraint.max}')
      end
      """

  Scenario: Values are invalid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate('', as: :min_length)
      puts Validate.validate('a long string', as: :max_length)
      puts Validate.validate('string', as: :between_length)
      puts Validate.validate('qwe', as: :exact_length)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      "" must have length of at least 3
      "a long string" must have length of at most 5
      "string" must have length between 3 and 5
      "qwe" must have length of 4
      """

  Scenario: Values are nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(nil, as: :min_length)
      puts Validate.validate(nil, as: :max_length)
      puts Validate.validate(nil, as: :between_length)
      puts Validate.validate(nil, as: :exact_length)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: Values are valid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate('qwe', as: :min_length)
      puts Validate.validate('12345', as: :max_length)
      puts Validate.validate('text', as: :between_length)
      puts Validate.validate('text', as: :exact_length)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
