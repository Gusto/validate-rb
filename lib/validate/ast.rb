# typed: strict
# frozen_string_literal: true

module Validate
  module AST
    def self.build(*args, &block)
      Generator.new
          .generate(*args, &block)
          .freeze
    end

    class DefinitionContext
      module Builder
        module_function

        def all_constraints(*constraints)
          Rules::Unanimous.new(constraints.map { |node| send(*node) })
        end

        def at_least_one_constraint(*constraints)
          Rules::Affirmative.new(constraints.map { |node| send(*node) })
        end

        def no_constraints(*constraints)
          Rules::Negative.new(constraints.map { |node| send(*node) })
        end

        def constraint(name, args, block, trace)
          if defined?(Constraints) && Constraints.respond_to?(name)
            begin
              return Constraints.send(name, *(args.map { |node| send(*node) }), &block)
            rescue => e
              ::Kernel.raise Error::ValidationRuleError, e.message, trace
            end
          end

          Rules::Pending.new(name, args.map { |node| send(*node) }, block, trace)
        end

        def value(value)
          value
        end
      end

      def self.create(*args, &block)
        ast = AST.build(*args, &block)
        context = new
        ast.each { |node| context.add_constraint(Builder.send(*node)) }
        context
      end

      def initialize
        @constraints = {}
      end

      def add_constraint(constraint)
        if @constraints.include?(constraint.name)
          raise Error::ValidationRuleError,
                "duplicate constraint #{constraint.name}"
        end

        @constraints[constraint.name] = constraint
        self
      end

      def evaluate(ctx)
        @constraints.each_value
            .reject { |c| catch(:pending) { c.valid?(ctx.value, ctx) } }
            .each { |c| ctx.add_violation(c) }
        ctx
      end
    end

    CORE_CONSTRAINTS = %i[
        not_nil not_blank not_empty
        is_a one_of validate
        min max equal match
        valid each_value unique
        length
      ].freeze

    class Generator < ::BasicObject
      def initialize
        @stack = []
      end

      def generate(*args, &block)
        instance_exec(*args, &block)

        if @stack.one? && @stack.first[0] == :all_constraints
          return @stack.first[1..-1]
        end

        @stack
      end

      def &(other)
        unless other == self
          ::Kernel.raise(
            Error::ValidationRuleError,
            'bad rule, only constraints and &, |, and ! operators allowed'
          )
        end

        right = @stack.pop
        left = @stack.pop
        if right[0] == :all_constraints
          right.insert(1, left)
          @stack << right
        else
          @stack << [:all_constraints, left, right]
        end
        self
      end

      def |(other)
        unless other == self
          ::Kernel.raise(
            Error::ValidationRuleError,
            'bad rule, only constraints and &, |, and ! operators allowed'
          )
        end

        right = @stack.pop
        left = @stack.pop
        if right[0] == :at_least_one_constraint
          right.insert(1, left)
          @stack << right
        else
          @stack << [:at_least_one_constraint, left, right]
        end
        self
      end

      def !
        prev = @stack.pop
        if prev[0] == :no_constraints
          @stack << prev[1]
        elsif prev[0] == :all_constraints
          prev[0] = :no_constraints
          @stack << prev
        else
          @stack << [:no_constraints, prev]
        end
        self
      end

      private

      def method_missing(method, *args, &block)
        return super unless respond_to_missing?(method)

        @stack << [
            :constraint,
            method,
            args.map { |arg| [:value, arg] },
            block,
            ::Kernel.caller
                .reject { |line| line.include?(__FILE__) }
        ]
        self
      end

      def respond_to_missing?(method, _ = false)
        (defined?(Constraints) && Constraints.respond_to?(method)) || CORE_CONSTRAINTS.include?(method)
      end
    end

    module Combinator
      extend Forwardable
      def_delegators :@constraints, :[]

      def respond_to_missing?(_, _ = false)
        false
      end

      private

      def constraint_message(index)
        @constraints[index].message % Hash.new do |_, key|
          if key.to_s.start_with?('constraint')
            "%{#{key.to_s.gsub('constraint', "constraint[#{index}]")}}"
          else
            "%{#{key}}"
          end
        end
      end
    end

    module Rules
      class Pending < Constraint
        include MonitorMixin

        def initialize(name, args, block, caller)
          @name = name
          @args = args
          @block = block
          @caller = caller
          @constraint = nil

          extend SingleForwardable
          mon_initialize
        end

        def name
          load_constraint { return @name }.name
        end

        def valid?(value, ctx = Constraints::ValidationContext.none)
          load_constraint { throw(:pending, true) }.valid?(value, ctx)
        end

        def to_s
          load_constraint { return "[pending #{@name}]" }.to_s
        end

        def inspect
          load_constraint { return "[pending #{@name}]" }.inspect
        end

        def ==(other)
          load_constraint { return false } == other
        end

        def method_missing(method, *args)
          load_constraint { return NameError }.__send__(method, *args)
        end

        def respond_to_missing?(method, pvt = false)
          load_constraint { return false }.__send__(:respond_to_missing?, method, pvt)
        end

        private

        def load_constraint
          yield unless defined?(Constraints) && Constraints.respond_to?(@name)

          synchronize do
            return @constraint if @constraint

            begin
              @constraint = Constraints.send(@name, *@args, &@block)
            rescue => e
              ::Kernel.raise Error::ValidationRuleError, e.message, @caller
            end

            def_delegators(:@constraint, :name, :valid?, :to_s,
                           :inspect, :==, :message)

            @name = @args = @block = @caller = nil
            @constraint
          end
        end
      end

      class Unanimous < Constraint
        include Combinator
        include Arguments

        arg(:constraints) do
          not_nil
          length(min: 2)
          each_value { is_a(Constraint) }
          unique(:name)
        end
        def initialize(constraints)
          @constraints = constraints.freeze
        end

        def valid?(value, _ = Constraints::ValidationContext.none)
          ctx = Constraints::ValidationContext.root(value)
          @constraints.all? do |c|
            c.valid?(value, ctx) && !ctx.has_violations?
          end
        end

        def name
          'both_' + @constraints.map(&:name).sort.join('_and_')
        end

        def inspect
          return @constraints.first.inspect if @constraints.one?

          "(#{@constraints.map(&:inspect).join(' & ')})"
        end

        def message
          'both ' + @constraints
                        .size
                        .times
                        .map { |i| "[#{constraint_message(i)}]" }
                        .join(', and ')
        end
      end

      class Affirmative < Constraint
        include Combinator
        include Arguments

        arg(:constraints) do
          not_nil
          length(min: 2)
          each_value { is_a(Constraint) }
          unique(:name)
        end
        def initialize(constraints)
          @constraints = constraints.freeze
        end

        def valid?(value, _ = Constraints::ValidationContext.none)
          ctx = Constraints::ValidationContext.root(value)
          @constraints.any? do |c|
            ctx.clear_violations
            c.valid?(value, ctx) && !ctx.has_violations?
          end
        end

        def name
          'either_' + @constraints.map(&:name).sort.join('_or_')
        end

        def inspect
          return @constraints.first.inspect if @constraints.one?

          "(#{@constraints.map(&:inspect).join(' | ')})"
        end

        def message
          'either ' + @constraints
                          .size
                          .times
                          .map { |i| "[#{constraint_message(i)}]" }
                          .join(', or ')
        end
      end

      class Negative < Constraint
        include Combinator
        include Arguments

        arg(:constraints) do
          not_nil
          not_empty
          each_value { is_a(Constraint) }
          unique(:name)
        end
        def initialize(constraints)
          @constraints = constraints.freeze
        end

        def valid?(value, _ = Constraints::ValidationContext.none)
          ctx = Constraints::ValidationContext.root(value)
          @constraints.none? do |c|
            ctx.clear_violations
            c.valid?(value, ctx) && !ctx.has_violations?
          end
        end

        def name
          'neither_' + @constraints.map(&:name).sort.join('_nor_')
        end

        def message
          return "not [#{constraint_message(0)}]" if @constraints.one?

          'neither ' + @constraints
                           .size
                           .times
                           .map { |i| "[#{constraint_message(i)}]" }
                           .join(', nor ')
        end

        def inspect
          return "!#{@constraints.first.inspect}" if @constraints.one?

          "!(#{@constraints.map(&:inspect).join(' & ')})"
        end
      end
    end
  end
end
