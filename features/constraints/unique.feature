Feature: Unique constraint

  `unique` constraint evaluates each values ensures that all elements in a collection are unique.
  If an attribute name is specified, it compares element by the values of that attribute.

  Background: Unique validator
    Given a file named "validator.rb" with:
      """ruby
      require 'validate'

      Named = Struct.new(:name)

      Validate::Validators.define(:non_repeating_items_collection) do
        unique(message: '%{value.inspect} must be unique')
      end

      Validate::Validators.define(:items_with_unique_names) do
        unique(:name, message: '%{value.inspect} must have unique names')
      end
      """

  Scenario: Values are invalid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate([1, 1], as: :non_repeating_items_collection)
      puts Validate.validate(['text', 'text'], as: :non_repeating_items_collection)
      puts Validate.validate([false, false], as: :non_repeating_items_collection)
      puts Validate.validate([Named.new('name'), Named.new('name')], as: :items_with_unique_names)
      """
    When I run `ruby script.rb`
    Then the output should contain exactly:
      """
      [1, 1] must be unique
      ["text", "text"] must be unique
      [false, false] must be unique
      [#<struct Named name="name">, #<struct Named name="name">] must have unique names
      """

  Scenario: Values are valid
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate([1, 2], as: :non_repeating_items_collection)
      puts Validate.validate(['text', 'more text'], as: :non_repeating_items_collection)
      puts Validate.validate([true, false], as: :non_repeating_items_collection)
      puts Validate.validate([Named.new('name'), Named.new('another name')], as: :items_with_unique_names)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything

  Scenario: Values are nil
    Given a file named "script.rb" with:
      """ruby
      require_relative 'validator.rb'

      puts Validate.validate(nil, as: :non_repeating_items_collection)
      puts Validate.validate(nil, as: :items_with_unique_names)
      """
    When I run `ruby script.rb`
    Then the output should not contain anything
