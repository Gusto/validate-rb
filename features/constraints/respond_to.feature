Feature: RespondTo constraint

  `respond_to` constraint guarantees object responds to method

  Background: RespondTo validator
    Given a file named "validator.rb" with:
      """ruby
      require 'validate'

      class TestClass
        def test_method
          puts "hello"
        end
      end

      Validate::Validators.define(:value) do
        respond_to(:test_method, message: '%{value.inspect} must respond to :%{constraint.method_name}')
      end
      """

  Scenario: Value is invalid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(false, as: :value)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      false must respond to :test_method
      """

  Scenario: Values are nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(nil, as: :value)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: Value is valid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(TestClass.new, as: :value)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
