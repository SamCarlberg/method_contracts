# TypeContracts

A pure Ruby implementation of runtime type checking.

This adds runtime type checking and validation to method parameters and return values.  By default, this gem only supports validating types and exact values, but custom matchers can be created and specified.  Contracts can be specified on parameters using the `params <param_name>, <contract>` syntax; contracts on return values can be specified by `returns <contract>`, `returns_a <Type>`, or `returns_an <Type>` (eg `returns_a String`, `returns_an ArrayOf(String)`).

Contracts can be specified as a module/class, which will test for inheritance (`param :foo, String`); an explicit value, which will test for equality `param :foo, 'A string'`; a regular expression (`param :foo, /An? (array|string)/`); an array of elements that all match the same contract (`param :foo, ArrayOf(String)`); a hash with keys matching one contract and values matching another (`param :hash, HashOf(Symbol, Integer)`); or an array of contracts, which will test that any contract in that array matches (`param :foo, [String, Symbol]` matches when `foo` is either a string or a symbol).

If none of the built-in contract types work, you can subclass `TypeContracts::Matchers::Base` and define the `match?(value)` and `to_s` methods, then pass an instance of your custom matcher to the `param` or `return` call.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'type_contracts'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install type_contracts

## Usage

### Type checks

```ruby
class C
  param :x, String
  param :y, Numeric
  param :z, Hash
  returns_an Array
  def takes_three(x, y, z)
    [x, y, z]
  end
end

C.new.takes_three('x', 1, { z: :z }) # => ['x', 1, { :z => :z }]
C.new.takes_three(:x, 1, { z: :z })  # => error!  x is a Symbol, but should be a String
```

### Value checks

```ruby
class C
  param :x, 1
  returns 'ok'
  def takes_specific_value(x)
    'ok'
  end
end

C.new.takes_specific_value(1) # => 'ok'
C.new.takes_specific_value(2) # => error!
```

### Regex checks

```ruby
class C
  param :value, /^mo[dmo]$/
  returns 'ok'
  def foo(value)
    'ok'
  end
end

C.new.foo('mod') # => 'ok'
C.new.foo('mom') # => 'ok'
C.new.foo('moo') # => 'ok'
C.new.foo('mop') # => error!
```

### Array checks

```ruby
class C
  param :strategy, %i[foo bar baz]
  returns 'ok'
  def takes_any_of(strategy)
    'ok'
  end
end

C.new.takes_any_of(:foo) # => 'ok'
C.new.takes_any_of(:bar) # => 'ok'
C.new.takes_any_of(:baz) # => 'ok'
C.new.takes_any_of(:wrong) # => error!
```

### Array checks with nested matchers

```ruby
class C
  param :x, [String, Symbol, 0, nil]
  returns 'ok'
  def takes_generic(x)
    'ok'
  end
end

C.new.takes_generic('string') # => 'ok'
C.new.takes_generic(:symbol) # => 'ok'
C.new.takes_generic(0) # => 'ok'
C.new.takes_generic(nil) # => 'ok'
C.new.takes_generic(1234) # => error!
```

### Structure checks

Checks can be added to check the structure of array or hash parameters and return values.  Use the `ArrayOf` helper method to define a contract that matches to every element of an array (it also checks that the parameter is itself an `Array`).  Similarly, the `HashOf` helper method can be used to define a contract for every key and a separate contract for every value in the hash.  Elementwise or key-/value-wise contracts can be specified as usual, so `param :nested_array, ArrayOf(ArrayOf(Integer))` will only match an array of arrays like `[[1, 2, 3], [4, 5, 6]]` but not `[[1, 2, 3], 4, 5, 6]`

```ruby
class C
  # :array takes an array of zero or more integers
  param :array, ArrayOf(Integer)
  param :hash, HashOf(Symbol, [String, Symbol])
  returns 'ok'
  def structured_args(array, hash)
    'ok'
  end

  param :array, ArrayOf(ArrayOf(Integer))
  returns 'ok'
  def accepts_nested_arrays(array)
    'ok'
  end
end

C.new.structured_args([], {}) # => 'ok'
C.new.structured_args([1, 2, 3], { foo: 'bar', bar: :baz }) # => 'ok'
C.new.structured_args(%w[1 2 3], {}) # => error!
C.new.structured_args([], { 'foo' => 'bar' }) # error!

C.new.accepts_nested_arrays([]) # => 'ok'
C.new.accepts_nested_arrays([[]]) # => 'ok'
C.new.accepts_nested_arrays([1, 2, 3]) # => error!  not a nested array
C.new.accepts_nested_arrays([[1, 2, 3]]) # => 'ok'
```

### Custom matcher logic

```ruby
class C
  param :x, ->(x) { x == [1, 2, 3] }
  returns 'ok'
  def custom_matcher_logic(x)
    'ok'
  end
end

C.new.custom_matcher_logic([1, 2, 3]) # => 'ok'
C.new.custom_matcher_logic([1, 2, 4]) # => error!
```

This can also be used by passing a block to the `param` or `returns` call.  Note that `param` needs parens around the parameter name if using curly braces for the block definition.

```ruby
class C
  param(:x) { |x| x == [1, 2, 3] }
  returns { |r| r == 'ok' }
  def custom_matcher_logic(x)
    'ok'
  end
end
```

### Create a custom matcher

```ruby
class PositiveNumber < TypeContracts::Matchers::Base
  def match?(value)
    value.is_a?(Numeric) && value > 0
  end

  def to_s
    'be a positive number'
  end
end

class UsingCustomMatcher
  param :bar, PositiveNumber
  def foo(bar)
    "ok"
  end
end

UsingCustomMatcher.new.foo(1) # => "ok"
UsingCustomMatcher.new.foo(0) # => TypeContracts::BrokenParamContractError: UsingCustomMatcher#foo.bar was 0, which does not match: be a positive number
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/samcarlberg/type_contracts.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Alternatives

### RBS

Ruby 3 introduced RBS, which is a built-in type system in the Ruby language.  However, it requires maintaining a separate file listing method signatures for each Ruby file, which requires manual work to keep the separate files in sync.

### Sorbet

[Sorbet](https://github.com/sorbet/sorbet) is probably better than this Gem.  I just didn't like the DSL for it.
