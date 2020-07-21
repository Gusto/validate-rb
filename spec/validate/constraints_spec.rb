# frozen_string_literal: true

RSpec.describe Validate::Constraints do
  describe '.define' do
    let(:instance) { double }

    it 'defines simple constraints' do
      Validate::Constraints.define(:pass) do
        evaluate { pass }
      end

      expect(Validate::Constraints.pass.valid?(nil)).to be true
    end

    it 'defines constrains with options' do
      Validate::Constraints.define(:equals) do
        option(:expected) { not_nil }
        evaluate { |value| fail unless options[:expected].eql?(value) }
      end

      expect(Validate::Constraints.equals(expected: instance).valid?(instance)).to be true
    end

    it 'raises on unsupported options' do
      Validate::Constraints.define(:no_options) do
      end

      expect do
        Validate::Constraints.no_options(unknown: false)
      end.to raise_error(ArgumentError, /unexpected options/)
    end

    it 'raises on unsupported options from initializer' do
      Validate::Constraints.define(:unknown_options) do
        initialize { { unknown: true } }
      end

      expect do
        Validate::Constraints.unknown_options
      end.to raise_error(ArgumentError, /unexpected options/)
    end

    it 'validates options' do
      Validate::Constraints.define(:with_options) do
        option(:values) { not_nil }
      end

      expect do
        Validate::Constraints.with_options(values: nil)
      end.to raise_error(ArgumentError) do |error|
        expect(error.cause).to be_a(Validate::Error::ConstraintViolationError)
        expect(error.cause.violations.size).to eq(1)
      end
    end
  end
end
