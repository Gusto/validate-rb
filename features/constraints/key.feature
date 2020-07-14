Feature: Key constraint

  `key` constraint evaluates object's key

  Background: Key validator
    Given a file named "validator.rb" with:
      """ruby
      require 'uri'

      require 'validate'

      Validate::Validators.define(:environment) do
        key('DATABASE_URL') do
          not_blank
          match(URI.regexp, message: 'be a URL')
        end

        key('RAILS_ENV') do
          not_blank
          one_of('production', 'development', 'testing')
        end
      end

      def validate_environment(env = ENV)
        Validate.validate(env, as: :environment)
                         .group_by(&:path)
                         .each do |path, violations|
                           puts "#{path.empty? ? 'address' : path}:"
                           violations.each do |violation|
                             puts "  must #{violation.message}"
                           end
                         end
      end
      """

  Scenario: Value is empty
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      validate_environment({})
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      ["DATABASE_URL"]:
        must not be blank
      ["RAILS_ENV"]:
        must not be blank
      """

  Scenario: Value has invalid DATABASE_URL
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      validate_environment({
        'DATABASE_URL' => 'qwe',
        'RAILS_ENV' => 'development'
      })
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      ["DATABASE_URL"]:
        must be a URL
      """

  Scenario: Value has invalid RAILS_ENV
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      validate_environment({
        'DATABASE_URL' => 'http://localhost:4300/schema',
        'RAILS_ENV' => 'staging'
      })
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      ["RAILS_ENV"]:
        must be one of ["production", "development", "testing"]
      """

  Scenario: Value is nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      validate_environment(nil)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: Values are valid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      validate_environment({
        'DATABASE_URL' => 'http://localhost:4300/schema',
        'RAILS_ENV' => 'development'
      })
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
