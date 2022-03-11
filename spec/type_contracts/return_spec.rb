# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeContracts::Return do
  let!(:clazz) do
    class Sample
      returns nil
      def returns_nil(x)
        x
      end

      returns String
      def returns_string(s)
        s
      end

      def unannotated(x)
        x
      end

      returns { |val| [1, 2].include?(val) }
      def blocked(x)
        x
      end
    end
  end

  after do
    # Undefine the helper class
    Object.send :remove_const, :Sample
  end

  it 'supports returning nil' do
    s = Sample.new

    expect { s.returns_nil(nil) }.not_to raise_error
    expect { s.returns_nil('not nil') }
      .to raise_error(
        TypeContracts::BrokenReturnValueContractError,
        'Sample#returns_nil returned "not nil", which does not match: equal nil'
      )
  end

  it 'supports returning a string' do
    s = Sample.new

    expect { s.returns_string(nil) }
      .to raise_error(
        TypeContracts::BrokenReturnValueContractError,
        'Sample#returns_string returned nil, which does not match: be a String'
      )
    expect { s.returns_string('string') }
      .not_to raise_error
  end

  it 'does not care about unannotated methods' do
    s = Sample.new

    expect(s.unannotated(nil)).to eq nil
  end

  it 'works when given a block' do
    s = Sample.new

    expect(s.blocked(1)).to eq 1
    expect { s.blocked(0) }.to raise_error(
      TypeContracts::BrokenReturnValueContractError,
      'Sample#blocked returned 0, which does not match: <custom matcher>'
    )
  end
end
