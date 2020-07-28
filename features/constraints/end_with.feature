Feature: EndWith constraint

  `end_with` constraint evaluates a string against a regular expression

  Background: EndWith validator
    Given a file named "validator.rb" with:
      """ruby
      require 'uri'

      require 'validate'

      Validate::Validators.define(:exclamation) do
        end_with('!', message: '%{value.inspect} must end with !')
      end

      Validate::Validators.define(:question) do
        end_with('?', message: '%{value.inspect} must end with ?')
      end
      """

  Scenario: Values are invalid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate('this will fail!', as: :question)
      puts Validate.validate('will this fail?', as: :exclamation)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      "this will fail!" must end with ?
      "will this fail?" must end with !
      """

  Scenario: Values are nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(nil, as: :question)
      puts Validate.validate(nil, as: :exclamation)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: Values are valid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate('will this fail?', as: :question)
      puts Validate.validate('this will fail!', as: :exclamation)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
