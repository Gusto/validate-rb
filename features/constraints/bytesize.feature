Feature: Bytesize constraint

  `bytesize` constraint guarantees object's byte length is within bounds

  Background: Bytesize validator
    Given a file named "validator.rb" with:
      """ruby
      require 'validate'

      Validate::Validators.define(:min_bytesize) do
        bytesize(min: 3, message: '%{value.inspect} must have byte length of at least %{constraint.min}')
      end

      Validate::Validators.define(:max_bytesize) do
        bytesize(max: 5, message: '%{value.inspect} must have byte length of at most %{constraint.max}')
      end

      Validate::Validators.define(:between_bytesize) do
        bytesize(3..5, message: '%{value.inspect} must have byte length between %{constraint.min} and %{constraint.max}')
      end

      Validate::Validators.define(:exact_bytesize) do
        bytesize(4, message: '%{value.inspect} must have byte length of %{constraint.max}')
      end
      """

  Scenario: Values are invalid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate('', as: :min_bytesize)
      puts Validate.validate('a long string', as: :max_bytesize)
      puts Validate.validate('string', as: :between_bytesize)
      puts Validate.validate('qwe', as: :exact_bytesize)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      "" must have byte length of at least 3
      "a long string" must have byte length of at most 5
      "string" must have byte length between 3 and 5
      "qwe" must have byte length of 4
      """

  Scenario: Values are nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(nil, as: :min_bytesize)
      puts Validate.validate(nil, as: :max_bytesize)
      puts Validate.validate(nil, as: :between_bytesize)
      puts Validate.validate(nil, as: :exact_bytesize)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: Values are valid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate('✓', as: :min_bytesize)
      puts Validate.validate('✓--', as: :max_bytesize)
      puts Validate.validate('-✓', as: :between_bytesize)
      puts Validate.validate('✓-', as: :exact_bytesize)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
