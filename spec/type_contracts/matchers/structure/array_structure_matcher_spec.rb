# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeContracts::Matchers::Structure::ArrayStructureMatcher do
  it 'supports basic matching' do
    matcher = described_class.new(String)

    expect(matcher.match?(['string'])).to eq true
    expect(matcher.match?([:not_a_string])).to eq false
    expect(matcher.match?(%w[a b c d e f g])).to eq true
  end

  it 'supports nested matching' do
    matcher = described_class.new(described_class.new(String))

    expect(matcher.match?(['string'])).to eq false
    expect(matcher.match?([['string']])).to eq true
    expect(matcher.match?(:does_not_match)).to eq false
  end

  it 'matches empty arrays' do
    matcher = described_class.new(String)

    expect(matcher.match?([])).to eq true
  end
end
