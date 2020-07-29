Feature: Uri constraint

  `uri` constraint checks that a string is a valid uri

  Background: Uri validator
    Given a file named "validator.rb" with:
      """ruby
      require 'uri'

      require 'validate'

      Validate::Validators.define(:relative_uri) do
        uri(absolute: false, message: '%{value.inspect} must be a relative uri')
      end

      Validate::Validators.define(:absolute_uri) do
        uri(message: '%{value.inspect} must be an absolute uri')
      end
      """

  Scenario: Values are invalid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate('https://example.com', as: :relative_uri)
      puts Validate.validate('//example.com', as: :absolute_uri)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      "https://example.com" must be a relative uri
      "//example.com" must be an absolute uri
      """

  Scenario: Value is nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(nil, as: :relative_uri)
      puts Validate.validate(nil, as: :absolute_uri)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: Values are valid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate('//example.com', as: :relative_uri)
      puts Validate.validate('https://example.com', as: :absolute_uri)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
