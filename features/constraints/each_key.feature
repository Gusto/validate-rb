Feature: EachKey constraint

  `each_key` constraint evaluates each values in a collection against a set of constraints.

  Background: EachKey validator
    Given a file named "validator.rb" with:
      """ruby
      require 'validate'

      Validate::Validators.define(:map) do
        each_key(message: '%{path}: %{value.inspect} must be a map') {}
      end

      Validate::Validators.define(:map_of_maps) do
        each_key(message: '%{path}: %{value.inspect} must be a map of maps') do
          not_nil(message: '%{path}: %{value.inspect} must not be nil')
          valid(:map_of_maps)
        end
      end
      """

  Scenario: Values are invalid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(false, as: :map)
      puts Validate.validate({false => nil}, as: :map_of_maps)
      puts Validate.validate({{false => nil} => nil}, as: :map_of_maps)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      .: false must be a map
      [false]: false must be a map of maps
      [{false=>nil}][false]: false must be a map of maps
      """

  Scenario: Values are empty maps
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate({}, as: :map_of_maps)
      puts Validate.validate({{} => nil}, as: :map_of_maps)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: Values have nils
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate({nil => nil}, as: :map_of_maps)
      puts Validate.validate({{nil => nil} => nil}, as: :map_of_maps)
      puts Validate.validate({{{{{nil => nil} => nil} => nil} => nil} => nil}, as: :map_of_maps)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      [nil]: nil must not be nil
      [{nil=>nil}][nil]: nil must not be nil
      [{{{{nil=>nil}=>nil}=>nil}=>nil}][{{{nil=>nil}=>nil}=>nil}][{{nil=>nil}=>nil}][{nil=>nil}][nil]: nil must not be nil
      """

  Scenario: Values are nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(nil, as: :map)
      puts Validate.validate(nil, as: :map_of_maps)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
