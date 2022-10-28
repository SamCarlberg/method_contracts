# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MethodContracts::Config do
  before do
    clean_reset
  end

  after do
    clean_reset
  end

  def clean_reset
    described_class.instance_variable_set(:@enabled, nil)
  end

  it 'defaults to be disabled' do
    expect(described_class.config.enabled).to eq false
  end

  it 'yields the config object when configuring' do
    c = described_class.configure { |c| c }
    expect(c).to eq(described_class.config)
  end

  it 'applies to Module when included everywhere' do
    expect(MethodContracts).to receive(:apply!).with(Module)

    described_class.config.enabled = true
    described_class.config.include_everywhere!
  end
end
