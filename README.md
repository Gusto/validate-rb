# Validate.rb

Yummy constraint validations for Ruby

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'validate-rb'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install validate-rb

## Usage

### Defining a validator

Validators are a collection of constraints

```ruby
require 'validate'

# validators can be named
Validate::Validators.define(:create_user_request) do
  # attr is a type of constraint that defines constraints on an attribute
  attr(:username) { not_blank }
  attr(:address) do
    not_nil
    # 'valid' constraint continues validation further down the object graph
    valid
  end
end

# validators can also be defined for a specific class
Validate::Validators.define(Address) do
  attr(:street) do
    not_blank
    is_a(String)
    attr(:length) { max(255) }
  end

  attr(:zip) do
    # constraints have default error messages, which can be changed
    match(/[0-9]{5}\-[0-9]{4}/, message: '%{value.inspect} must be a zip')
  end
end

address = Address.new(street: '123 Any Road', zip: '11223-3445')
request = CreateUser.new(username: 'janedoe',
                         address: address)

violations = Validate.validate(request, as: :create_user_request)

violations.group_by(&:path).each do |path, violations|
  puts "#{path} is invalid:"
  violations.each do |v|
    puts "  #{v.message}"
  end
end
```

### Creating constraints

Constraints have properties and can be evaluated

```ruby
# constraints must have a name
Validate::Constraints.define(:not_blank) do
  # evaluation can 'fail' or 'pass'
  evaluate { |value| fail if value.nil? || value.empty? }
end

# 'attr' is just another constraint, like 'not_blank'
Validate::Constraints.define(:attr) do
  # constraints can have options
  # every constraint at least has a :message option
  # constraint options can have validation constraints
  option(:name) { not_blank & is_a(Symbol) }
  option(:validator) { is_a(Validate::Validators::Validator) }

  # by default, constraints expect **kwargs for options
  # initializer can be defined to translates from arbitrary args to options map
  initialize do |name, &validation_block|
    {
      name: name,
      # validators can be created anonymously
      validator: Validate::Validators.create(&validation_block)
    }
  end

  evaluate do |value, ctx|
    # pass constraints on non-values to support optional validation
    pass if value.nil?

    # fetch an option
    name = options[:name]
    fail unless value.respond_to?(name)

    # validation context can be used to traverse object graph
    # `ValidationContext#attr(attribute)` creates a `ValidationContext` for object's `attribute`
    # there is also `ValidationContext#key` to validate keys in a hash, useful for ENV validation
    attr_ctx = ctx.attr(name)
    options[:validator]&.validate(attr_ctx)
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/gusto-validation.

