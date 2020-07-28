# frozen_string_literal: true

module Validate
  module Constraints
    class ValidationContext
      def self.none
        @none ||= None.new
      end

      def self.root(value, violations = [])
        new(value, Path.new, violations)
      end

      def self.key(key, violations = [])
        new(key, Path.new([KeyPath.new(key)]), violations)
      end

      attr_reader :value, :violations
      protected :violations

      def initialize(value, path = Path.new, violations = [])
        @value      = value
        @path       = path
        @violations = violations
        @keys = Hash.new do |hash, key|
          unless @value.respond_to?(:[]) || @value.respond_to_missing?(:[])
            raise Error::KeyError,
                  "#{key.inspect}: value doesn't respond to :[]"
          end
          begin
            hash[key] = child_context(@value[key], KeyPath.new(key))
          rescue => e
            raise Error::KeyError,
                  "#{key.inspect}: #{e.message}",
                  cause: e
          end
        end
        @attrs = Hash.new do |hash, attr|
          unless @value.respond_to?(attr) || @value.respond_to_missing?(attr)
            raise Error::NameError,
                  "#{attr.inspect}: value doesn't respond to #{attr.inspect}"
          end
          hash[attr] = child_context(@value.send(attr), AttrPath.new(attr))
        end
      end

      def [](key)
        @keys[key]
      end

      def attr(name)
        @attrs[name]
      end

      def add_violation(constraint)
        @violations << create_violation(constraint)
        self
      end

      def clear_violations
        @violations.clear
        self
      end

      def has_violations?
        !@violations.empty?
      end

      def to_err
        Error::ConstraintViolationError.new(@violations.freeze)
      end

      def merge(other)
        other.violations.each do |violation|
          @violations << Constraint::Violation.new(violation.value, @path.child(violation.path), violation.constraint)
        end
        self
      end

      private

      def create_violation(constraint)
        Constraint::Violation.new(@value, @path, constraint)
      end

      def child_context(value, path)
        ValidationContext.new(value, @path.child(path), @violations)
      end

      class Path
        extend Forwardable

        def_delegators(:@paths, :empty?, :length, :size, :each)

        include Enumerable

        def initialize(paths = [])
          @paths = paths
        end

        def child(path)
          case path
          when KeyPath, AttrPath
            Path.new(@paths.dup << path)
          when Path
            Path.new(@paths.dup << path.to_a)
          end
        end

        def to_s
          return '.' if @paths.empty?

          @paths.join
        end

        def at(index)
          raise Error::IndexError if index.negative?

          return nil if index.zero?
          @paths.fetch(index - 1)
        end

        def inspect
          return "#<#{self.class.name} <root>>" if @paths.empty?

          "#<#{self.class.name} #{to_s}>"
        end
      end

      class KeyPath
        def initialize(key)
          @key = key
        end

        def to_s
          "[#{@key.inspect}]"
        end

        def inspect
          "#<#{self.class.name} #{@key.inspect}>"
        end
      end

      class AttrPath
        def initialize(attr)
          @attr = attr
        end

        def to_s
          ".#{@attr}"
        end

        def inspect
          "#<#{self.class.name} #{@attr.inspect}>"
        end
      end

      class None < ValidationContext
        def initialize
        end

        def [](_)
          self
        end

        def attr(_)
          self
        end

        def add_violation(_)
          self
        end

        def clear_violations
          self
        end

        def has_violations?
          false
        end
      end
    end
  end
end
