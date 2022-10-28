# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MethodContracts::Param do
  before do
    allow(MethodContracts.config)
      .to receive(:enabled?)
      .and_return(true)
  end

  let!(:clazz) do
    class ParamsSampleClass
      extend MethodContracts::T

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
        { args: args, kwargs: kwargs }
      end

      param :a, Symbol
      param :b, Symbol
      param :c, Symbol
      param :rest, ArrayOf(Symbol)
      param :d, Symbol
      param :e, Symbol
      param :kwargs, Hash
      def with_all_param_types(a, b, c = :default_c, *rest, d, e: :named_e, **kwargs)
        { a: a, b: b, c: c, rest: rest, d: d, e: e, kwargs: kwargs }
      end

      param :x, Integer
      def self.self_method(x)
        x
      end

      class << self
        # The metaclass doesn't get the mixins, so we need to re-include it here
        extend MethodContracts::T

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
        MethodContracts::BrokenParamContractError,
        'ParamsSampleClass#foo.x was "1", which does not match: be a Integer'
      )

    expect { s.foo(nil) }
      .to raise_error(
        MethodContracts::BrokenParamContractError,
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
        MethodContracts::ParameterDoesNotExistError,
        'Parameter ParamsSampleClass#incorrectly_annotated.does_not_exist does not exist'
      )
  end

  it 'works for an array of types' do
    s = ParamsSampleClass.new

    expect { s.one_of_many('string') }.not_to raise_error
    expect { s.one_of_many(:symbol) }.not_to raise_error
    expect { s.one_of_many(nil) }
      .to raise_error(
        MethodContracts::BrokenParamContractError,
        'ParamsSampleClass#one_of_many.x was nil, which does not match: <any of: be a String, be a Symbol>'
      )
  end

  it 'works with two params specified' do
    s = ParamsSampleClass.new

    expect { s.two_params('str', 1) }.not_to raise_error
    expect { s.two_params(:not_a_string, 1) }
      .to raise_error(
        MethodContracts::BrokenParamContractError,
        'ParamsSampleClass#two_params.a was :not_a_string, which does not match: be a String'
      )
    expect { s.two_params('string', :NaN) }
      .to raise_error(
        MethodContracts::BrokenParamContractError,
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
        MethodContracts::BrokenParamContractError,
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
      MethodContracts::BrokenParamContractError,
      'ParamsSampleClass#self_method.x was :not_an_int, which does not match: be a Integer'
    )
  end

  it 'supports singleton methods' do
    skip 'TODO: support this!'

    expect(ParamsSampleClass.singleton_class_method(10)).to eq 10
    expect { ParamsSampleClass.singleton_class_method(:not_an_int) }.to raise_error(
      MethodContracts::BrokenParamContractError,
      'ParamsSampleClass#singleton_class_method.x was :not_an_int, which does not match: be a Integer'
    )
  end

  it 'supports attr_writer-generated methods' do
    class WithAttrWriter
      extend MethodContracts::T

      param :value, String
      attr_writer :attr_writer_property
    end

    o = WithAttrWriter.new

    expect { o.attr_writer_property = 'a string' }
      .to change { o.instance_variable_get(:@attr_writer_property) }
      .from(nil)
      .to('a string')

    expect { o.attr_writer_property = :not_a_string }.to raise_error(
      MethodContracts::BrokenParamContractError,
      'WithAttrWriter#attr_writer_property=.value was :not_a_string, which does not match: be a String'
    )
  end

  it 'supports attr_accessor-generated methods' do
    class WithAttrAccessor
      extend MethodContracts::T

      param :value, String
      attr_accessor :attr_accessor_property
    end

    o = WithAttrAccessor.new

    expect { o.attr_accessor_property = 'a string' }
      .to change { o.attr_accessor_property }
      .from(nil)
      .to('a string')

    expect { o.attr_accessor_property = :not_a_string }.to raise_error(
      MethodContracts::BrokenParamContractError,
      'WithAttrAccessor#attr_accessor_property=.value was :not_a_string, which does not match: be a String'
    )
  end

  it 'supports inherited methods' do
    class Superclass
      extend MethodContracts::T

      param :x, String
      def inherited_method(x)
        x
      end
    end

    class Subclass < Superclass; end

    expect { Subclass.new.inherited_method(:not_a_string) }.to raise_error(
      MethodContracts::BrokenParamContractError,
      'Subclass#inherited_method.x was :not_a_string, which does not match: be a String'
    )
  end

  it 'supports inherited methods that call super' do
    class Superclass
      extend MethodContracts::T

      param :x, String
      def inherited_method(x)
        x
      end
    end

    class Subclass < Superclass
      def inherited_method(*)
        super
      end
    end

    expect { Subclass.new.inherited_method(:not_a_string) }.to raise_error(
      MethodContracts::BrokenParamContractError,
      'Subclass#inherited_method.x was :not_a_string, which does not match: be a String'
    )
  end

  it 'supports methods added from including a mixin' do
    module Mixin
      extend MethodContracts::T

      param :x, String
      def mixin_method(x)
        x
      end
    end

    class User
      include Mixin
    end

    expect { User.new.mixin_method(:not_a_string) }.to raise_error(
      MethodContracts::BrokenParamContractError,
      'User#mixin_method.x was :not_a_string, which does not match: be a String'
    )
  end

  it 'supports methods added from extending another module' do
    module Extendee
      extend MethodContracts::T

      param :x, String
      def mixin_method(x)
        x
      end
    end

    class Extender
      extend Extendee
    end

    expect { Extender.mixin_method(:not_a_string) }.to raise_error(
      MethodContracts::BrokenParamContractError,
      'Extender#mixin_method.x was :not_a_string, which does not match: be a String'
    )
  end
end
