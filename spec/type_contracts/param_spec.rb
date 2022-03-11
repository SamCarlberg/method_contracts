# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeContracts::Param do
  let!(:clazz) do
    class Sample
      param :x, Integer
      def foo(x)
        @x = x
      end

      param :x, [String, Symbol]
      def one_of_many(x); end

      def no_params
        __method__
      end

      param :does_not_exist, Object
      def incorrectly_annotated
        __method__
      end

      param :a, String
      param :b, Numeric
      def two_params(a, b)
        [a, b]
      end
    end
  end

  after do
    # Undefine the helper class
    Object.send :remove_const, :Sample
  end

  it 'defines the `param` annotation method' do
    s = Sample.new
    s.foo(1)
    expect(s.instance_variable_get(:@x)).to eq 1
  end

  it 'validates the param type' do
    s = Sample.new

    expect { s.foo(1) }.not_to raise_error

    expect { s.foo('1') }
      .to raise_error(
        TypeContracts::BrokenParamContractError,
        'Sample#foo.x was "1", which does not match: be a Integer'
      )

    expect { s.foo(nil) }
      .to raise_error(
        TypeContracts::BrokenParamContractError,
        'Sample#foo.x was nil, which does not match: be a Integer'
      )
  end

  it 'works when a method has no annotations' do
    s = Sample.new

    expect(s.no_params).to eq :no_params
  end

  it 'raises an error if a no-params method is annotated' do
    s = Sample.new

    expect { s.incorrectly_annotated }
      .to raise_error(
        TypeContracts::ParameterDoesNotExistError,
        'Parameter Sample#incorrectly_annotated.does_not_exist does not exist'
      )
  end

  it 'works for an array of types' do
    s = Sample.new

    expect { s.one_of_many('string') }.not_to raise_error
    expect { s.one_of_many(:symbol) }.not_to raise_error
    expect { s.one_of_many(nil) }
      .to raise_error(
        TypeContracts::BrokenParamContractError,
        'Sample#one_of_many.x was nil, which does not match: <any of: be a String, be a Symbol>'
      )
  end

  it 'works with two params specified' do
    s = Sample.new

    expect { s.two_params('str', 1) }.not_to raise_error
    expect { s.two_params(:not_a_string, 1) }
      .to raise_error(
        TypeContracts::BrokenParamContractError,
        'Sample#two_params.a was :not_a_string, which does not match: be a String'
      )
    expect { s.two_params('string', :NaN) }
      .to raise_error(
        TypeContracts::BrokenParamContractError,
        'Sample#two_params.b was :NaN, which does not match: be a Numeric'
      )
  end
end
