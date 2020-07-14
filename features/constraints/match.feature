Feature: Match constraint

  `match` constraint evaluates a string against a regular expression

  Background: Match validator
    Given a file named "validator.rb" with:
      """ruby
      require 'uri'

      require 'validate'

      Validate::Validators.define(:uri) do
        match(URI.regexp, message: '%{value.inspect} must be a url')
      end

      Validate::Validators.define(:email) do
        match(URI::MailTo::EMAIL_REGEXP, message: '%{value.inspect} must be an email')
      end
      """

  Scenario: Values are invalid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate('jane.doe@example.com', as: :uri)
      puts Validate.validate('', as: :email)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      "jane.doe@example.com" must be a url
      "" must be an email
      """

  Scenario: Values are nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(nil, as: :uri)
      puts Validate.validate(nil, as: :email)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: Values are valid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate('http://www.example.com', as: :uri)
      puts Validate.validate('jane.doe@example.com', as: :email)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
