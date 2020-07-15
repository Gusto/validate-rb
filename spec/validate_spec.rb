# frozen_string_literal: true

RSpec.describe Validate do
  it 'has a version number' do
    expect(Validate::VERSION).not_to be nil
  end

  it 'should fail' do
    expect(false).to be true
  end
end
