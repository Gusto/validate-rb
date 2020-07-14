Feature: Equal constraint

  `equal` constraint evaluates object's equality

  Background: Equal validator
    Given a file named "validator.rb" with:
      """ruby
      require 'validate'

      Duration = Struct.new(:seconds, :nanoseconds)

      Validate::Validators.define(:equal_value) do
        equal(5, message: '%{value} must be exactly %{constraint.equal}')
      end

      Validate::Validators.define(:equal_duration) do
        equal(Validate::Compare.attributes(seconds: 0, nanoseconds: 1000),
              message: '%{value} must be exactly %{constraint.equal.seconds} seconds and %{constraint.equal.nanoseconds} nanoseconds')
      end
      """

  Scenario: Values are invalid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(6, as: :equal_value)
      puts Validate.validate(Duration.new(1, 0), as: :equal_duration)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      6 must be exactly 5
      #<struct Duration seconds=1, nanoseconds=0> must be exactly 0 seconds and 1000 nanoseconds
      """

  Scenario: Values are nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(nil, as: :equal_value)
      puts Validate.validate(nil, as: :equal_duration)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: Values are valid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(5, as: :equal_value)
      puts Validate.validate(Duration.new(0, 1000), as: :equal_duration)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
