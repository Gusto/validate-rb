Feature: Uuid constraint

  `uuid` constraint checks that a string is a properly formatted uuid

  Background: Uuid validator
    Given a file named "validator.rb" with:
      """ruby
      require 'uri'

      require 'validate'

      Validate::Validators.define(:uuid) do
        uuid(message: '%{value.inspect} must be a uuid')
      end
      """

  Scenario: Values are invalid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate('this will fail', as: :uuid)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      "this will fail" must be a uuid
      """

  Scenario: Values are nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(nil, as: :uuid)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: Values are valid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'
      require 'securerandom'

      puts Validate.validate(SecureRandom.uuid, as: :uuid)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
