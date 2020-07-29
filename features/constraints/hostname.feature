Feature: Hostname constraint

  `hostname` constraint checks that a string is a valid hostname

  Background: Hostname validator
    Given a file named "validator.rb" with:
      """ruby
      require 'uri'

      require 'validate'

      Validate::Validators.define(:hostname) do
        hostname(message: '%{value.inspect} must be a hostname')
      end
      """

  Scenario: Values are invalid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate('this will fail', as: :hostname)
      puts Validate.validate('this/will/fail/too', as: :hostname)
      puts Validate.validate('bad\\hostname', as: :hostname)
      puts Validate.validate('this?not:a|hostname', as: :hostname)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      "this will fail" must be a hostname
      "this/will/fail/too" must be a hostname
      "bad\\hostname" must be a hostname
      "this?not:a|hostname" must be a hostname
      """

  Scenario: Value is nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(nil, as: :hostname)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: Values are valid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate('www.example.com', as: :hostname)
      puts Validate.validate('10.10.10.10', as: :hostname)
      puts Validate.validate('[2001:db8:85a3:8d3:1319:8a2e:370:7348]', as: :hostname)
      puts Validate.validate('127.0.0.1', as: :hostname)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
