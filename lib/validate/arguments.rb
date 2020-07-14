module Validate
  module Arguments
    module ClassMethods
      def method_added(method_name)
        super
        return if @args.empty?

        method = instance_method(method_name)
        guard = ArgumentsGuard.new(method, @args.dup)

        @methods_guard.__send__(:define_method, method_name) do |*args, &block|
          guard.send(method_name, *args, &block)
          super(*args, &block)
        end
      ensure
        @args.clear
      end

      def singleton_method_added(method_name)
        super
        return if @args.empty?

        method = singleton_method(method_name)
        guard = ArgumentsGuard.new(method, @args.dup)

        @methods_guard.__send__(:define_singleton_method, method_name) do |*args, &block|
          guard.send(method_name, *args, &block)
          super(*args, &block)
        end
      ensure
        @args.clear
      end

      def arg(name, &body)
        if @args.include?(name)
          raise Error::ArgumentError, "duplicate argument :#{name}"
        end

        @args[name] = Assertions.create(&body)
        self
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.instance_exec do
        @args = {}
        prepend(@methods_guard = Module.new)
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
            raise Error::ArgumentError, "unsupported parameter type #{kind}"
          end
          next unless rules.include?(name)

          assertions << "@rules[:#{name}].assert(#{name}, message: 'invalid argument #{name}')"
        end

        singleton_class.class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
            def #{method.name}(#{signature.join(', ')})
              #{assertions.join("\n  ")}
            end
        RUBY

        @rules = rules
      end
    end
  end
end
