Feature: IpAddress constraint

  `ip_address` constraint checks that a string is a valid ip address

  Background: IpAddress validator
    Given a file named "validator.rb" with:
      """ruby
      require 'uri'

      require 'validate'

      Validate::Validators.define(:ip) do
        ip_address(message: '%{value.inspect} must be an ip address')
      end

      Validate::Validators.define(:ipv4) do
        ip_address(:v4, message: '%{value.inspect} must be an ipv4 address')
      end

      Validate::Validators.define(:ipv6) do
        ip_address(:v6, message: '%{value.inspect} must be an ipv6 address')
      end
      """

  Scenario: Values are invalid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate('not an ip', as: :ip)
      puts Validate.validate('2001:db8:85a3::8a2e:370:7334', as: :ipv4)
      puts Validate.validate('10.10.0.13', as: :ipv6)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      "not an ip" must be an ip address
      "2001:db8:85a3::8a2e:370:7334" must be an ipv4 address
      "10.10.0.13" must be an ipv6 address
      """

  Scenario: Value is nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(nil, as: :ip)
      puts Validate.validate(nil, as: :ipv4)
      puts Validate.validate(nil, as: :ipv6)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: Values are valid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate('10.10.0.13', as: :ip)
      puts Validate.validate('2001:db8:85a3::8a2e:370:7334', as: :ip)
      puts Validate.validate('10.10.0.13', as: :ipv4)
      puts Validate.validate('2001:db8:85a3::8a2e:370:7334', as: :ipv6)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
