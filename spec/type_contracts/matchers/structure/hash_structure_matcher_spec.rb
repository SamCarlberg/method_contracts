# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeContracts::Matchers::Structure::HashStructureMatcher do
  it 'supports basic matching' do
    matcher = described_class.new(Symbol, Symbol)

    expect(matcher.match?({ key: :value })).to eq true
    expect(matcher.match?({ key: 'value' })).to eq false
    expect(matcher.match?({ 'key' => :value })).to eq false

    expect(matcher.match?({ k1: :v1, k2: :v2, k3: :v3 })).to eq true
  end

  it 'matches empty hashes' do
    matcher = described_class.new(String, String)

    expect(matcher.match?({})).to eq true
  end
end
