Feature: EachValue constraint

  `each_value` constraint evaluates each values in a collection against a set of constraints.

  Background: EachValue validator
    Given a file named "validator.rb" with:
      """ruby
      require 'validate'

      Validate::Validators.define(:list) do
        each_value(message: '%{path}: %{value.inspect} must be a list') {}
      end

      Validate::Validators.define(:list_of_lists) do
        each_value(message: '%{path}: %{value.inspect} must be a list of lists') do
          not_nil(message: '%{path}: %{value.inspect} must not be nil')
          valid(:list_of_lists)
        end
      end
      """

  Scenario: Values are invalid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(false, as: :list)
      puts Validate.validate([false], as: :list_of_lists)
      puts Validate.validate([[false]], as: :list_of_lists)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      .: false must be a list
      [0]: false must be a list of lists
      [0][0]: false must be a list of lists
      """

  Scenario: Values are empty lists
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate([], as: :list_of_lists)
      puts Validate.validate([[]], as: :list_of_lists)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: Values have nils
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate([nil], as: :list_of_lists)
      puts Validate.validate([[nil]], as: :list_of_lists)
      puts Validate.validate([[[[[nil]]]]], as: :list_of_lists)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      [0]: nil must not be nil
      [0][0]: nil must not be nil
      [0][0][0][0][0]: nil must not be nil
      """

  Scenario: Values are nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(nil, as: :list)
      puts Validate.validate(nil, as: :list_of_lists)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
