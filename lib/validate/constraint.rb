# typed: strict
# frozen_string_literal: true

module Validate
  class Constraint
    class Violation
      attr_reader :value, :path, :constraint

      def initialize(value, path, constraint)
        @value = value
        @path = path
        @constraint = constraint
      end

      def message(template = @constraint.message)
        (template % parameters).strip
      end

      alias to_s message

      private

      def parameters
        @parameters ||= Hash.new do |_, key|
          String(instance_eval(key.to_s))
        end
      end
    end

    class Option
      attr_reader :name

      def initialize(name, default:, assertion: nil, &assert_block)
        @name = name
        @default = default.is_a?(Proc) ? default : -> { default }
        @assertion = assertion || assert_block && Assertions.create(&assert_block)
      end

      def replace_default(default)
        Option.new(@name, default: default, assertion: @assertion)
      end

      def get_or_default(options)
        value = options.delete(@name) { return @default&.call }
        @assertion&.assert(value, message: "invalid option #{@name}")
        value
      end
    end

    def self.inherited(child)
      child.extend DSL
    end

    def self.create_class(name, **defaults, &constraint_block)
      Class.new(self) do
        @supported_options = common_options.transform_values do |option|
          defaults.include?(option.name) ? option.replace_default(defaults[option.name]) : option
        end
        include(@constraint_user_methods = Module.new)
        @constraint_user_methods.define_method(:name) { name.to_s }
        class_eval(&constraint_block)
        if instance_variable_defined?(:@supported_options)
          initialize { |**options| options }
        end
      end
    end

    module DSL
      def constraint_name
        @constraint_name ||= Assertions.create do
          not_nil(message: 'constraint name must not be nil')
          is_a(Symbol, message: 'constraint name must be a Symbol')
        end
      end
      module_function :constraint_name

      def common_options
        @common_options ||= {
            message: Option.new(:message, default: 'be %{constraint.name}') do
              not_blank
              is_a(String)
            end
        }.freeze
      end
      module_function :common_options

      def option(
          name,
          default: lambda do
            raise Error::KeyError,
                  "option #{name.inspect} is required for #{self.name}"
          end,
          &assert_block
      )
        constraint_name.assert(name)
        if @supported_options.include?(name)
          raise Error::ArgumentError, "duplicate option :#{name}"
        end

        @supported_options[name] = Option.new(
            name,
            default: default,
            &assert_block
        )
        self
      end

      def initialize(&initialize_block)
        supported_options = @supported_options
        expects_kwargs = false
        initialize_block.parameters.each do |(kind, name)|
          if %i(keyreq key).include?(kind) && supported_options.include?(name)
            raise Error::ArgumentError,
                  "key name #{name}: conflicts with an existing option"
          end
          expects_kwargs = true if kind == :keyrest
        end

        define_constraint_method(:initialize, initialize_block) do |*args, &block|
          if args.last.is_a?(Hash)
            known_options, kwargs =
                args.pop
                    .partition { |k, _| supported_options.include?(k) }
                    .map { |h| Hash[h] }

            if !expects_kwargs && !kwargs.empty?
              args << kwargs
              kwargs = {}
            end

            if expects_kwargs
              merged_options = {}.merge!(super(*args, **kwargs, &block), known_options)
            else
              args << kwargs unless kwargs.empty?
              merged_options = {}.merge!(super(*args, &block), known_options)
            end
          else
            merged_options = super(*args, &block)
          end

          options = supported_options.each_with_object({}) do |(n, opt), opts|
            opts[n] = opt.get_or_default(merged_options)
          end

          unless merged_options.empty?
            raise Error::ArgumentError,
                  "unexpected options #{merged_options.inspect}"
          end

          @options = options.freeze
        end
        remove_instance_variable(:@supported_options)
      end

      def evaluate(&validation_block)
        define_constraint_method(:valid?, validation_block) do |*args|
          catch(:result) do
            super(*args[0...validation_block.arity])
            :pass
          end == :pass
        end
        self
      end

      def describe(&describe_block)
        define_method(:to_s, &describe_block)
        self
      end

      def key(&key_block)
        define_method(:name, &key_block)
        self
      end

      private

      def define_constraint_method(name, body, &override)
        @constraint_user_methods.__send__(:define_method, name, &body)
        define_method(name, &override)
        self
      end
    end

    attr_reader :options
    protected :options

    def initialize(**options)
      @options = options
    end

    def name
      raise ::NotImplementedError
    end

    def valid?(value, ctx = Constraints::ValidationContext.none)
      raise ::NotImplementedError
    end

    def to_s
      name.to_s.gsub('_', ' ')
    end

    def inspect
      "#<#{self.class.name} #{@options.map { |name, value| "#{name}: #{value.inspect}" }.join(', ')}>"
    end

    def ==(other)
      other.is_a?(Constraint) && other.name == name && other.options == options
    end

    def respond_to_missing?(method, _ = false)
      @options.include?(method)
    end

    def method_missing(method, *args)
      return super unless args.empty? || respond_to_missing?(method)

      @options[method]
    end

    private

    def fail
      throw(:result, :fail)
    end

    def pass
      throw(:result, :pass)
    end
  end
end
