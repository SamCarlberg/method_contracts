# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeContracts::Param do
  let!(:clazz) do
    class ParamsSampleClass
      extend TypeContracts::T

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

      param :args, ArrayOf(Integer)
      param :kwargs, HashOf(Symbol, Integer)
      def splatted(*args, **kwargs)
        { args:, kwargs: }
      end

      param :a, Symbol
      param :b, Symbol
      param :c, Symbol
      param :rest, ArrayOf(Symbol)
      param :d, Symbol
      param :e, Symbol
      param :kwargs, Hash
      def with_all_param_types(a, b, c = :default_c, *rest, d, e: :named_e, **kwargs)
        { a:, b:, c:, rest:, d:, e:, kwargs: }
      end

      param :x, Integer
      def self.self_method(x)
        x
      end

      class << self
        # The metaclass doesn't get the mixins, so we need to re-include it here
        extend TypeContracts::T

        param :x, Integer
        def singleton_class_method(x)
          x
        end
      end
    end
  end

  after do
    # Undefine the helper class
    Object.send :remove_const, :ParamsSampleClass
  end

  it 'defines the `param` annotation method' do
    s = ParamsSampleClass.new
    s.foo(1)
    expect(s.instance_variable_get(:@x)).to eq 1
  end

  it 'validates the param type' do
    s = ParamsSampleClass.new

    expect { s.foo(1) }.not_to raise_error

    expect { s.foo('1') }
      .to raise_error(
        TypeContracts::BrokenParamContractError,
        'ParamsSampleClass#foo.x was "1", which does not match: be a Integer'
      )

    expect { s.foo(nil) }
      .to raise_error(
        TypeContracts::BrokenParamContractError,
        'ParamsSampleClass#foo.x was nil, which does not match: be a Integer'
      )
  end

  it 'works when a method has no annotations' do
    s = ParamsSampleClass.new

    expect(s.no_params).to eq :no_params
  end

  it 'raises an error if a no-params method is annotated' do
    s = ParamsSampleClass.new

    expect { s.incorrectly_annotated }
      .to raise_error(
        TypeContracts::ParameterDoesNotExistError,
        'Parameter ParamsSampleClass#incorrectly_annotated.does_not_exist does not exist'
      )
  end

  it 'works for an array of types' do
    s = ParamsSampleClass.new

    expect { s.one_of_many('string') }.not_to raise_error
    expect { s.one_of_many(:symbol) }.not_to raise_error
    expect { s.one_of_many(nil) }
      .to raise_error(
        TypeContracts::BrokenParamContractError,
        'ParamsSampleClass#one_of_many.x was nil, which does not match: <any of: be a String, be a Symbol>'
      )
  end

  it 'works with two params specified' do
    s = ParamsSampleClass.new

    expect { s.two_params('str', 1) }.not_to raise_error
    expect { s.two_params(:not_a_string, 1) }
      .to raise_error(
        TypeContracts::BrokenParamContractError,
        'ParamsSampleClass#two_params.a was :not_a_string, which does not match: be a String'
      )
    expect { s.two_params('string', :NaN) }
      .to raise_error(
        TypeContracts::BrokenParamContractError,
        'ParamsSampleClass#two_params.b was :NaN, which does not match: be a Numeric'
      )
  end

  it 'supports variadic splat args' do
    s = ParamsSampleClass.new

    # expect(s.splatted).to eq({ args: [], kwargs: {} })
    # expect(s.splatted(1, 2, 3)).to eq({ args: [1, 2, 3], kwargs: {} })
    # expect(s.splatted(foo: 1)).to eq({ args: [], kwargs: { foo: 1 } })

    expect { s.splatted('1', '2', '3') }
      .to raise_error(
        TypeContracts::BrokenParamContractError,
        'ParamsSampleClass#splatted.args was ["1", "2", "3"], which does not match: an array of elements matching be a Integer'
      )
  end

  it 'supports all param types' do
    s = ParamsSampleClass.new

    # With all args
    expect(s.with_all_param_types(:a, :b, :c, :blah, :blah, :blah, :d, e: :named_e, kwarg1: 1, kwarg2: 2))
      .to eq({
        a: :a,
        b: :b,
        c: :c,
        rest: [:blah, :blah, :blah],
        d: :d,
        e: :named_e,
        kwargs: { kwarg1: 1, kwarg2: 2 }
      })

    # Without vararg or kwarg arguments
    expect(s.with_all_param_types(:a, :b, :c, :d, e: :named_e))
      .to eq({
        a: :a,
        b: :b,
        c: :c,
        rest: [],
        d: :d,
        e: :named_e,
        kwargs: {}
      })
  end

  it 'supports self.<method> methods' do
    expect(ParamsSampleClass.self_method(10)).to eq 10
    expect { ParamsSampleClass.self_method(:not_an_int) }.to raise_error(
      TypeContracts::BrokenParamContractError,
      'ParamsSampleClass#self_method.x was :not_an_int, which does not match: be a Integer'
    )
  end

  it 'supports singleton methods' do
    skip 'TODO: support this!'

    expect(ParamsSampleClass.singleton_class_method(10)).to eq 10
    expect { ParamsSampleClass.singleton_class_method(:not_an_int) }.to raise_error(
      TypeContracts::BrokenParamContractError,
      'ParamsSampleClass#singleton_class_method.x was :not_an_int, which does not match: be a Integer'
    )
  end
end
