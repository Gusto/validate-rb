Feature: Max constraint

  `max` constraint evaluates object's upper boundary

  Background: Max validator
    Given a file named "validator.rb" with:
      """ruby
      require 'validate'

      Duration = Struct.new(:seconds, :nanoseconds)

      Validate::Validators.define(:max_value) do
        max(5, message: '%{value} must be at most %{constraint.max}')
      end

      Validate::Validators.define(:max_duration) do
        max(Validate::Compare.attributes(seconds: 0, nanoseconds: 1000),
            message: '%{value} must be at most %{constraint.max.seconds} seconds and %{constraint.max.nanoseconds} nanoseconds')
      end
      """

  Scenario: Values are invalid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(6, as: :max_value)
      puts Validate.validate(Duration.new(1, 0), as: :max_duration)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      6 must be at most 5
      #<struct Duration seconds=1, nanoseconds=0> must be at most 0 seconds and 1000 nanoseconds
      """

  Scenario: Values are nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(nil, as: :max_value)
      puts Validate.validate(nil, as: :max_duration)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: Values are valid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(5, as: :max_value)
      puts Validate.validate(Duration.new(0, 1000), as: :max_duration)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
