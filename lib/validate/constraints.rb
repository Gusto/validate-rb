# frozen_string_literal: true

module Validate
  module Constraints
    include Validate::Arguments

    @reserved_names = Hash[%i[define validation_context].map { |n| [n, n] }]

    arg(:name) do
      not_blank(message: 'constraint name must not be blank')
      is_a(Symbol, message: 'constraint name must be a Symbol')
    end
    arg(:body) do
      not_nil(message: 'constraint body is required')
    end
    def self.define(name, **defaults, &body)
      if @reserved_names.include?(name)
        raise Error::ArgumentError,
              "#{name} is already defined"
      end

      @reserved_names[name] = name
      constraint_class = Constraint.create_class(name, **defaults, &body)
      Constraints.const_set(Helpers.camelize(name), constraint_class)
      define_method(name, &constraint_class.method(:new))
      module_function(name)
    end

    define(:not_nil, message: 'not be nil') do
      evaluate { |value| fail if value.nil? }
    end

    define(:not_blank, message: 'not be blank') do
      evaluate do |value|
        fail if value.nil? || !value.respond_to?(:empty?) || value.empty?
      end
    end

    define(:not_empty, message: 'not be empty') do
      evaluate { |value| fail if value&.empty? }
    end

    define(:is_a, message: 'be a %{constraint.klass}') do
      option(:klass) do
        not_nil(message: 'klass is required')
      end

      initialize { |klass| { klass: klass } }
      evaluate do |value|
        pass if value.nil?

        klass = options[:klass]
        fail unless klass === value
      end
    end

    define(:respond_to, message: 'respond to %{constraint.method_name.inspect}') do
      option(:method_name) do
        not_blank(message: 'method_name is required')
        is_a(Symbol, message: 'method_name must be a Symbol')
      end

      initialize do |method_name|
        method_name.nil? ? {} : { method_name: method_name }
      end
      evaluate do |instance|
        pass if instance.nil?
        fail unless instance.respond_to?(options[:method_name])
      end
      key { "respond_to_#{options[:method_name]}" }
    end

    define(:length, message: 'have length of %{constraint.describe_length}') do
      option(:min) { respond_to(:>, message: 'min must respond to :>') }
      option(:max) { respond_to(:<, message: 'max must respond to :<') }

      initialize do |range = nil|
        case range
        when ::Range
          { min: range.min, max: range.max }
        else
          { min: range, max: range }
        end
      end
      evaluate do |value|
        pass if value.nil?
        fail unless value.respond_to?(:length)

        length = value.length
        fail if (options[:min]&.> length) || (options[:max]&.< length)
      end

      def describe_length
        if options[:max] == options[:min]
          options[:max].to_s
        elsif options[:max].nil?
          "at least #{options[:min]}"
        elsif options[:min].nil?
          "at most #{options[:max]}"
        else
          "at least #{options[:min]} and at most #{options[:max]}"
        end
      end
      key { "length_over_#{options[:min]}_under_#{options[:max]}" }
    end

    define(:bytesize, message: 'have byte length of %{constraint.describe_length}') do
      option(:min) { respond_to(:>, message: 'min must respond to :>') }
      option(:max) { respond_to(:<, message: 'max must respond to :<') }

      initialize do |range = nil|
        case range
        when ::Range
          { min: range.min, max: range.max }
        else
          { min: range, max: range }
        end
      end
      evaluate do |value|
        pass if value.nil?
        fail unless value.respond_to?(:bytesize)

        bytesize = value.bytesize
        fail if (options[:min]&.> bytesize) || (options[:max]&.< bytesize)
      end

      def describe_length
        if options[:max] == options[:min]
          options[:max].to_s
        elsif options[:max].nil?
          "at least #{options[:min]}"
        elsif options[:min].nil?
          "at most #{options[:max]}"
        else
          "at least #{options[:min]} and at most #{options[:max]}"
        end
      end
      key { "bytesize_over_#{options[:min]}_under_#{options[:max]}" }
    end

    define(:one_of, message: 'be %{constraint.describe_presence}') do
      option(:values) do
        respond_to(:include?, message: 'values must respond to :include?')
      end

      initialize do |*values|
        if values.one? && values.first.respond_to?(:include?)
          { values: values.first }
        else
          { values: values }
        end
      end
      evaluate do |value|
        pass if value.nil?

        values = options[:values]
        pass if values.respond_to?(:cover?) && values.cover?(value)
        fail unless values.include?(value)
      end

      def describe_presence
        case options[:values]
        when ::Hash
          "one of #{options[:values].keys}"
        when ::Range
          "covered by #{options[:values]}"
        else
          "one of #{options[:values]}"
        end
      end
    end

    define(:validate, message: 'pass validation') do
      option(:using) do
        not_nil(message: 'using is required')
        is_a(Proc, message: 'using must be a Proc')
      end

      initialize { |&validate_block| { using: validate_block } }
      evaluate do |value|
        pass if value.nil?
        fail unless instance_exec(value, &options[:using])
      end
    end

    define(:attr, message: 'have attribute %{constraint.attribute}') do
      option(:attribute) do
        not_nil(message: 'attribute is required')
        is_a(Symbol, message: 'attribute must be a Symbol')
      end
      option(:constraints) do
        is_a(AST::DefinitionContext, message: 'constraints must be a DefinitionContext')
      end

      initialize do |attribute, &block|
        { attribute: attribute,
          constraints: block && AST::DefinitionContext.create(&block) }
      end
      evaluate do |value, ctx|
        pass if value.nil?

        attribute = options[:attribute]
        begin
          options[:constraints].evaluate(ctx.attr(attribute))
        rescue NameError
          fail
        end
      end
      key { "attr_#{options[:attribute]}" }
    end

    define(:key, message: 'have key %{constraint.key.inspect}') do
      option(:key) do
        not_nil(message: 'key is required')
      end
      option(:constraints) do
        is_a(AST::DefinitionContext, message: 'constraints must be a DefinitionContext')
      end

      initialize do |key, &block|
        { key: key,
          constraints: block && AST::DefinitionContext.create(&block) }
      end

      evaluate do |instance, ctx|
        pass if instance.nil?
        fail unless instance.respond_to?(:[])

        key = options[:key]
        begin
          options[:constraints]&.evaluate(ctx[key])
        rescue KeyError
          fail
        end
      end
      key { "key_#{options[:key]}" }
    end

    define(:min, message: 'be at least %{constraint.min}') do
      option(:min) do
        not_nil(message: 'min is required')
        respond_to(:>, message: 'min must respond to :>')
      end

      initialize do |min = nil|
        min.nil? ? {} : { min: min }
      end
      evaluate do |value|
        pass if value.nil?
        fail if options[:min] > value
      end
    end

    define(:max, message: 'be at most %{constraint.max}') do
      option(:max) do
        not_nil(message: 'max is required')
        respond_to(:<, message: 'max must respond to :<')
      end

      initialize do |max = nil|
        max.nil? ? {} : { max: max }
      end
      evaluate do |value|
        pass if value.nil?
        fail if options[:max] < value
      end
    end

    define(:equal, message: 'be equal to %{constraint.equal}') do
      option(:equal) do
        not_nil(message: 'equal is required')
        respond_to(:==, message: 'equal must respond to :==')
      end

      initialize do |equal = nil|
        equal.nil? ? {} : { equal: equal }
      end
      evaluate do |value|
        pass if value.nil?
        fail unless options[:equal] == value
      end
    end

    define(:match, message: 'match %{constraint.regexp}') do
      option(:regexp) do
        not_nil(message: 'regexp is required')
        respond_to(:=~, message: 'regexp must respond to :=~')
      end

      initialize do |regexp = nil|
        regexp.nil? ? {} : { regexp: regexp }
      end
      evaluate do |value|
        pass if value.nil?
        fail unless value.is_a?(String) && options[:regexp] =~ value
      end
    end

    define(:valid, message: 'be valid %{constraint.validator || value.class}') do
      option(:validator, default: nil)

      initialize do |validator = nil|
        validator.nil? ? {} : { validator: validator }
      end
      evaluate do |value, ctx|
        pass if value.nil?

        Scope.current
            .validator(options[:validator] || value.class)
            .validate(ctx)
      end
      key { options[:validator] && "valid_#{options[:validator]}" || 'valid' }
    end

    define(:each_value, message: 'have values') do
      option(:constraints) do
        not_nil(message: 'constraints are required')
        is_a(AST::DefinitionContext, message: 'constraints must be a DefinitionContext')
      end

      initialize do |&block|
        return {} if block.nil?

        { constraints: AST::DefinitionContext.create(&block) }
      end
      evaluate do |collection, ctx|
        pass if collection.nil?
        fail unless collection.respond_to?(:each)

        constraints = options[:constraints]
        case collection
        when ::Hash
          collection.each do |key, value|
            constraints.evaluate(ctx[key])
          end
        else
          i = 0
          collection.each do |value|
            constraints.evaluate(ctx[i])
            i += 1
          end
        end
      end
    end

    define(:each_key, message: 'have keys') do
      option(:constraints) do
        not_nil(message: 'constraints are required')
        is_a(AST::DefinitionContext, message: 'constraints must be a DefinitionContext')
      end

      initialize do |&block|
        return {} if block.nil?

        { constraints: AST::DefinitionContext.create(&block) }
      end
      evaluate do |collection, ctx|
        pass if collection.nil?
        fail unless collection.respond_to?(:each_key)

        constraints = options[:constraints]
        collection.each_key do |key|
          key_ctx = Constraints::ValidationContext.key(key)
          constraints.evaluate(key_ctx)
          ctx.merge(key_ctx) if key_ctx.has_violations?
        end
      end
    end

    define(:start_with, message: 'start with %{constraint.prefix}') do
      option(:prefix) do
        not_blank(message: 'prefix is required')
        is_a(String, message: 'prefix must be a String')
      end

      initialize do |prefix = nil|
        return {} if prefix.nil?

        { prefix: prefix }
      end
      evaluate do |value|
        pass if value.nil?
        fail unless value.respond_to?(:start_with?) && value.start_with?(options[:prefix])
      end
      key do
        "start_with_#{options[:prefix]}"
      end
    end

    define(:end_with, message: 'end with %{constraint.suffix}') do
      option(:suffix) do
        not_blank(message: 'suffix is required')
        is_a(String, message: 'suffix must be a String')
      end

      initialize do |suffix = nil|
        return {} if suffix.nil?

        { suffix: suffix }
      end
      evaluate do |value|
        pass if value.nil?
        fail unless value.respond_to?(:end_with?) && value.end_with?(options[:suffix])
      end
      key do
        "end_with_#{options[:suffix]}"
      end
    end

    define(:contain, message: 'contain %{constraint.substring}') do
      option(:substring) do
        not_blank(message: 'substring is required')
        is_a(String, message: 'substring must be a String')
      end

      initialize do |substring = nil|
        return {} if substring.nil?

        { substring: substring }
      end
      evaluate do |value|
        pass if value.nil?
        fail unless value.respond_to?(:include?) && value.include?(options[:substring])
      end
      key do
        "contain_#{options[:substring]}"
      end
    end

    define(:uuid, message: 'be a uuid') do
      UUID_REGEXP = %r{\b\h{8}\b-\h{4}-\h{4}-\h{4}-\b\h{12}\b}

      evaluate do |value|
        pass if value.nil?
        fail unless UUID_REGEXP.match?(value.to_s)
      end
    end

    define(:hostname, message: 'be a hostname') do
      HOSTNAME_REGEXP = URI::HOST

      evaluate do |value|
        pass if value.nil?
        fail unless HOSTNAME_REGEXP.match?(value.to_s)
      end
    end

    define(:uri, message: 'be a uri') do
      option(:absolute, default: true) do
        one_of([true, false], message: ':absolute must be true or false')
      end

      evaluate do |value|
        pass if value.nil?
        uri = begin
                URI.parse(value)
              rescue URI::Error
                fail
              end
        fail unless options[:absolute] == uri.absolute?
      end
    end

    define(
        :unique,
        message: 'have unique %{constraint.describe_unique_attribute}'
    ) do
      option(:attribute, default: nil) do
        is_a(Symbol, message: 'attribute %{value.inspect} must be a Symbol')
      end

      initialize do |attribute = nil|
        attribute.nil? ? {} : { attribute: attribute }
      end
      evaluate do |value|
        pass if value.nil?
        fail unless value.respond_to?(:uniq) && value.respond_to?(:size)
        fail unless value.size == value.uniq(&options[:attribute]).size
      end
      key do
        options[:attribute] && "unique_#{options[:attribute]}" || 'unique'
      end

      def describe_unique_attribute
        options[:attribute] || 'values'
      end
    end
  end
end
