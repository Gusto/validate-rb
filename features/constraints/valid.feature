Feature: Valid constraint

  `valid` constraint evaluates object against a specific validator.
  It is best used with `attr`, `key` or `each_value` constraints for deep validation of the entire object graph

  Background: Match validator
    Given a file named "validator.rb" with:
      """ruby
      require 'uri'

      require 'validate'

      Customer = Struct.new(:name, :email, :address)
      Address = Struct.new(:street, :zip)

      Validate::Validators.define(:email) do
        match(URI::MailTo::EMAIL_REGEXP, message: 'be a valid email')
      end

      Validate::Validators.define(Customer) do
        attr(:name) { not_blank }

        attr(:email) { not_nil & valid(:email) }

        attr(:address) { not_nil & valid }
      end

      Validate::Validators.define(Address) do
        attr(:street) do
          not_blank
          length(3..255)
        end

        attr(:zip) do
          not_blank
          match(/\A[0-9]{5}(?:-[0-9]{4})?\Z/, message: 'be a zip code')
        end
      end

      Validate::Validators.define(:list_of_customers) do
        not_empty
        each_value { not_nil & valid(Customer) }
      end

      def group_violations(violations)
        violations.each_with_object({ errors: [], children: {} }) do |violation, hash|
          level = violation.path.inject(hash) do |h, path_component|
            h[:children][path_component.to_s] ||= { errors: [], children: {} }
          end
          level[:errors] << "must #{violation.message}"
        end
      end

      def print_violations(current_level, indent = 0)
        current_level[:errors].each do |error|
          puts "#{' ' * indent}#{error}"
        end

        current_level[:children].each do |name, next_level|
          puts "#{' ' * indent}#{name}:"
          print_violations(next_level, indent + 2)
        end
      end

      def validate(*args, **kwargs)
        print_violations group_violations(Validate.validate(*args, **kwargs))
      end
      """

  Scenario: Customer attributes are missing
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      validate(Customer.new)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      .name:
        must not be blank
      .email:
        must not be nil
      .address:
        must not be nil
      """

  Scenario: Customer has invalid email
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      validate(Customer.new('Jane Doe', 'not_valid', Address.new('123 Any Rd', '12345')))
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      .email:
        must be a valid email
      """

  Scenario: Customer has invalid address
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      validate(Customer.new('Jane Doe', 'jane.doe@example.com', Address.new(nil, '1')))
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      .address:
        .street:
          must not be blank
        .zip:
          must be a zip code
      """

  Scenario: Customer is nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      validate(nil, as: Customer)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: Customer is valid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      validate(Customer.new('Jane Doe', 'jane.doe@example.com', Address.new('123 Any Street', '12345-6789')))
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: List of customers is empty
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      validate([], as: :list_of_customers)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      must not be empty
      """

  Scenario: List of customers has an invalid entry at position 1
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      validate([
        Customer.new('Jane Doe', 'jane.doe@example.com', Address.new('123 Any Street', '12345-6789')),
        Customer.new
      ], as: :list_of_customers)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      [1]:
        .name:
          must not be blank
        .email:
          must not be nil
        .address:
          must not be nil
      """

  Scenario: List of customers has a nil entry at position 0
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      validate([
        nil,
        Customer.new('Jane Doe', 'jane.doe@example.com', Address.new('123 Any Street', '12345-6789'))
      ], as: :list_of_customers)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      [0]:
        must not be nil
      """

  Scenario: List of customers is valid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      validate([
        Customer.new('Jane Doe', 'jane.doe@example.com', Address.new('123 Any Street', '12345-6789')),
        Customer.new('John Smith', 'john.smith@example.com', Address.new('456 Nowhere Avenue', '45678-1234'))
      ], as: :list_of_customers)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: List of customers is nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      validate(nil, as: :list_of_customers)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
