Feature: Validation
  Object validation in ruby using annotations

  Scenario: Constraints are used to validate objects
    Given a file named "script.rb" with:
      """ruby
      require 'rspec/expectations'
      require 'validate'

      Validate::Constraints.define(:integer) do
        evaluate do |value|
          pass if value.nil?
          Integer(value) rescue fail
        end
      end

      Validate::Constraints.define(:size) do
        option(:min) { integer }
        option(:max) { integer }

        initialize { |range| { max: range.max, min: range.min } }
        evaluate do |value|
          pass if value.nil?
          fail if (options[:max] && value > options[:max])
          fail if (options[:min] && value < options[:min])
        end
      end

      Validate::Constraints.define(:unique_row) do
        option(:table)
        option(:column)

        evaluate do |value|
          pass if value.nil?
          fail unless sql("SELECT 1 FROM ? WHERE ? = ?", table, column, value).empty?
        end
      end

      Validate::Constraints.define(:same_as) do
        option(:field) { not_nil & is_a(Symbol) }

        initialize { |field| { field: field } }

        evaluate do |value, ctx|
          pass if value.nil?
          fail unless value == ctx.root.value(field)
        end
      end

      Validate::Validators.define(:user_request) do
        attr(:username) do
          not_blank
          size(3..15)
          unique_row(table: 'users', column: 'username')
        end
        attr(:role) { not_blank & one_of('User', 'Admin') }
        attr(:email) { not_blank & match(URI::MailTo::EMAIL_REGEXP, message: 'be an email') }
        attr(:password) { not_blank }
        attr(:password_repeat) { not_blank & same_as(:password) }
      end

      CreateUserRequest = Struct.new(:username, :role, :email, :password, :password_repeat)

      violations = Validate.validate(CreateUserRequest.new(nil, "Test", 'qwe', nil, nil), as: :user_request)

      include RSpec::Matchers
      expect(violations).to_not be_empty

      violations.group_by(&:path).each do |path, violations|
        puts "#{path} is invalid:"
        violations.each do |v|
          puts "  must #{v.message}"
        end
      end
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      .username is invalid:
        must not be blank
      .role is invalid:
        must be one of ["User", "Admin"]
      .email is invalid:
        must be an email
      .password is invalid:
        must not be blank
      .password_repeat is invalid:
        must not be blank
      """

  Scenario: Constraints are used to refer to specific validators
    Given a file named "script.rb" with:
      """ruby
      require 'rspec/expectations'
      require 'validate'

      Validate::Validators.define(:attribute) do
        not_nil & attr(:size) { min(4) & max(5) }
      end

      Validate::Validators.define(:root) do
        attr(:attribute) { valid(:attribute) }
      end

      class Root
        attr_reader :attribute

        def initialize(attribute)
          @attribute = attribute
        end
      end

      violations = Validate.validate(Root.new([1,2,3,4,5]), as: :root)

      include RSpec::Matchers
      expect(violations).to be_empty
      """
    When I run `ruby script.rb`
    Then the exit status should be 0

  Scenario: Validation is defined at class level
    Given a file named "script.rb" with:
      """ruby
      require 'time'

      require 'rspec/expectations'
      require 'validate'

      class User
        include Validate

        validator do
          attr(:username) { not_blank & is_a(String) }
          attr(:full_name) { not_blank & is_a(String) }
          attr(:date_of_birth) { not_nil & is_a(Date) }
        end

        attr_reader :username, :full_name, :date_of_birth

        def initialize(username:, full_name:, date_of_birth:)
          @username = username
          @full_name = full_name
          @date_of_birth = date_of_birth
        end
      end

      violations = Validate.validate(User.new(username: nil, full_name: nil, date_of_birth: nil))

      include RSpec::Matchers
      expect(violations).to_not be_empty

      violations.group_by(&:path).each do |path, violations|
        puts "#{path} is invalid:"
        violations.each do |v|
          puts "  must #{v.message}"
        end
      end
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      .username is invalid:
        must not be blank
      .full_name is invalid:
        must not be blank
      .date_of_birth is invalid:
        must not be nil
      """

  Scenario: Validation constraints can guard method parameters
    Given a file named "script.rb" with:
      """ruby
      require 'validate'

      module Print
        include Validate::Arguments
        extend self

        arg(:value) { not_nil & is_a(String) }
        def is_a_string(value)
          puts "#{value.inspect} is a string"
        end

        arg(:symbols) { not_empty & each_value { not_nil & is_a(Symbol) } }
        def is_a_list_of_symbols(*symbols)
          puts "#{symbols.inspect} is a list of symbols"
        end

        arg(:a) { not_nil & is_a(String) }
        arg(:b) { not_nil & is_a(Integer) }
        arg(:c) { not_nil & is_a(Array) & each_value { one_of(true, false) } }
        def is_kwrags(a:, b:, c:)
          puts "a: #{a.inspect}, b: #{b.inspect}, c: #{c.inspect} kwargs"
        end
      end
      """
    When I run the following script with `ruby`:
      """ruby
      require './script'
      require 'rspec/expectations'
      include RSpec::Matchers

      expect { Print.is_a_string(123) }.to raise_error(Validate::Error::ArgumentError)
      expect { Print.is_a_list_of_symbols }.to raise_error(Validate::Error::ArgumentError)
      expect { Print.is_kwrags(a: nil, b: nil, c: nil) }.to raise_error(Validate::Error::ArgumentError)

      Print.is_a_string("actual string")
      Print.is_a_list_of_symbols(:a, :b, :c)
      Print.is_kwrags(a: '', b: 0, c: [true, false])
      """
    Then it should pass with:
      """
      "actual string" is a string
      [:a, :b, :c] is a list of symbols
      a: "", b: 0, c: [true, false] kwargs
      """
