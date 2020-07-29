module Validate
  module Arguments
    module ClassMethods
      def method_added(method_name)
        super
        guard_method(instance_method(method_name), @methods_guard)
      end

      def singleton_method_added(method_name)
        super
        guard_method(singleton_method(method_name), @singleton_methods_guard)
      end

      def arg(name, &body)
        if @args.include?(name)
          raise Error::ArgumentError, "duplicate argument :#{name}"
        end

        @args[name] = Assertions.create(&body)
        self
      end

      private

      def guard_method(method, guard_module)
        return if @args.empty?
        guard = ArgumentsGuard.new(method, @args)
        guard_module.__send__(:define_method, method.name) do |*args, &block|
          guard.enforce!(*args, &block)
          super(*args, &block)
        end
      ensure
        @args = {}
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.instance_exec do
        @args = {}
        prepend(@methods_guard = Module.new)
        singleton_class.prepend(@singleton_methods_guard = Module.new)
      end
    end

    class ArgumentsGuard
      DEFAULT_VALUE = BasicObject.new

      def initialize(method, rules)
        signature = []
        assertions = []

        method.parameters.each do |(kind, name)|
          case kind
          when :req
            signature << name.to_s
          when :opt
            signature << "#{name} = DEFAULT_VALUE"
          when :rest
            signature << "*#{name}"
          when :keyreq
            signature << "#{name}:"
          when :key
            signature << "#{name}: DEFAULT_VALUE"
          when :keyrest
            signature << "**#{name}"
          when :block
            signature << "&#{name}"
          else
            raise Error::ArgumentError,
                  "unsupported parameter type #{kind}"
          end
          next unless rules.include?(name)

          assertions <<
            "@rules[:#{name}].assert(#{name}, message: '#{name}') unless #{name}.eql?(DEFAULT_VALUE)"
        end

        singleton_class.class_eval(<<~RUBY, __FILE__, __LINE__)
          def enforce!(#{signature.join(', ')})
            #{assertions.join("\n  ")}
          end
        RUBY

        @rules = rules
      end
    end
  end
end
