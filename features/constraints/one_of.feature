Feature: OneOf constraint

  `one_of` constraint guarantees object to be present a given collection

  Background: OneOf validator
    Given a file named "validator.rb" with:
      """ruby
      require 'validate'

      class TestClass
        def test_method
          puts "hello"
        end
      end

      Validate::Validators.define(:present_in_array) do
        one_of([1, 2, 3], message: '%{value.inspect} must be one of %{constraint.values}')
      end

      Validate::Validators.define(:present_in_hash) do
        one_of(a: 1, b: 2, c: 3, message: '%{value.inspect} must be present in %{constraint.values}')
      end

      Validate::Validators.define(:present_in_range) do
        one_of(1..5, message: '%{value.inspect} must be covered by %{constraint.values}')
      end
      """

  Scenario: Values are invalid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(0, as: :present_in_array)
      puts Validate.validate(:d, as: :present_in_hash)
      puts Validate.validate(6, as: :present_in_range)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      0 must be one of [1, 2, 3]
      :d must be present in {:a=>1, :b=>2, :c=>3}
      6 must be covered by 1..5
      """

  Scenario: Values are nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(nil, as: :present_in_array)
      puts Validate.validate(nil, as: :present_in_hash)
      puts Validate.validate(nil, as: :present_in_range)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: Values are valid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(1, as: :present_in_array)
      puts Validate.validate(:b, as: :present_in_hash)
      puts Validate.validate(4, as: :present_in_range)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
