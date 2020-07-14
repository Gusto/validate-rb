Feature: Attr constraint

  `attr` constraint evaluates object's attributes

  Background: Attr validator
    Given a file named "validator.rb" with:
      """ruby
      require 'validate'

      Address = Struct.new(:street, :zip)

      Validate::Validators.define(:address) do
        attr(:street) do
          not_blank
          length(3..255)
        end

        attr(:zip) do
          not_blank
          (length(5) | length(10))
          match(/\A[0-9]{5}(?:-[0-9]{4})?\Z/)
        end
      end

      def validate_address(address)
        Validate.validate(address, as: :address)
                         .group_by(&:path)
                         .each do |path, violations|
                           puts "#{path.empty? ? 'address' : path}:"
                           violations.each do |violation|
                             puts "  must #{violation.message}"
                           end
                         end
      end
      """

  Scenario: Value is not an address
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      validate_address(false)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      address:
        must have attribute street
        must have attribute zip
      """

  Scenario: Value is an empty address
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      validate_address(Address.new)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      .street:
        must not be blank
      .zip:
        must not be blank
      """

  Scenario: Value is an invalid address
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      validate_address(Address.new('a', '1234'))
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      .street:
        must have length of at least 3 and at most 255
      .zip:
        must either [have length of 5], or [have length of 10]
        must match (?-mix:\A[0-9]{5}(?:-[0-9]{4})?\Z)
      """

  Scenario: Value is nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      validate_address(nil)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: Values are valid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      validate_address(Address.new('123 Nowhere St.', '12345'))
      validate_address(Address.new('123 Nowhere St.', '12345-6789'))
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
