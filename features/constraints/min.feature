Feature: Min constraint

  `min` constraint evaluates object's lower boundary

  Background: Min validator
    Given a file named "validator.rb" with:
      """ruby
      require 'validate'

      Duration = Struct.new(:seconds, :nanoseconds)

      Validate::Validators.define(:min_value) do
        min(5, message: '%{value} must be at least %{constraint.min}')
      end

      Validate::Validators.define(:min_duration) do
        min(Validate::Compare.attributes(seconds: 0, nanoseconds: 1000),
            message: '%{value} must be at least %{constraint.min.seconds} seconds and %{constraint.min.nanoseconds} nanoseconds')
      end
      """

  Scenario: Values are invalid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(3, as: :min_value)
      puts Validate.validate(Duration.new(0, 1), as: :min_duration)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      3 must be at least 5
      #<struct Duration seconds=0, nanoseconds=1> must be at least 0 seconds and 1000 nanoseconds
      """

  Scenario: Values are nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(nil, as: :min_value)
      puts Validate.validate(nil, as: :min_duration)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: Values are valid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(5, as: :min_value)
      puts Validate.validate(Duration.new(0, 1000), as: :min_duration)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
