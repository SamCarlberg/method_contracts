# TypeContracts

A pure Ruby implementation of runtime type checking.

This adds runtime type checking and validation to method parameters and return values.  By default, this gem only supports validating types and exact values, but custom matchers can be created and specified

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
  returns Array # or returns_a Array
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
  def takes_specific_value(x)
    'ok'
  end
end

C.new.takes_specific_value(1) # => 'ok'
C.new.takes_specific_value(2) # => error!
```

### Array checks

```ruby
class C
  param :strategy, %i[foo bar baz]
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

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/type_contracts.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Alternatives

### RBS

Ruby 3 introduced RBS, which is a built-in type system in the Ruby language.  However, it requires maintaining a separate file listing method signatures for each Ruby file, which requires manual work to keep the separate files in sync.

### Sorbet

[Sorbet](https://github.com/sorbet/sorbet) is probably better than this Gem.  I just didn't like the DSL for it.
