Feature: IsA constraint

  `is_a` constraint guarantees that value matches desired case

  Background: IsA validator
    Given a file named "validator.rb" with:
      """ruby
      require 'validate'

      module TestModule
      end

      class TestClass
        include TestModule
      end

      class CustomCaseMatcher
        def ===(other)
          TestClass === other
        end

        def to_s
          "custom case match"
        end
      end

      Validate::Validators.define(:an_instance_of_test_class) do
        is_a(TestClass, message: '%{value.inspect} must be a %{constraint.klass}')
      end

      Validate::Validators.define(:an_instance_of_test_module) do
        is_a(TestModule, message: '%{value.inspect} must be a %{constraint.klass}')
      end

      Validate::Validators.define(:matching_custom_case) do
        is_a(CustomCaseMatcher.new, message: '%{value.inspect} must be a %{constraint.klass}')
      end
      """

  Scenario: Values are invalid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(false, as: :an_instance_of_test_class)
      puts Validate.validate(1, as: :an_instance_of_test_module)
      puts Validate.validate('', as: :matching_custom_case)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      false must be a TestClass
      1 must be a TestModule
      "" must be a custom case match
      """

  Scenario: Value is nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(nil, as: :an_instance_of_test_class)
      puts Validate.validate(nil, as: :an_instance_of_test_module)
      puts Validate.validate(nil, as: :matching_custom_case)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: Value is a case match
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(TestClass.new, as: :an_instance_of_test_class)
      puts Validate.validate(TestClass.new, as: :an_instance_of_test_module)
      puts Validate.validate(TestClass.new, as: :matching_custom_case)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
