# SuperCallbacks

[![CI](https://github.com/jrpolidario/super_callbacks/actions/workflows/ci.yml/badge.svg)](https://github.com/jrpolidario/super_callbacks/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/super_callbacks.svg)](https://badge.fury.io/rb/super_callbacks)

* Allows `before` and `after` callbacks to any Class.
* Supports "dirty" checking of instance variables changes
* Supports both class and instance level callbacks
* Supports conditional callbacks
* Supports inherited callbacks; hence named "Super", get it? :D haha!

---

* Focuses on performance and flexibility as intended primarily for game development, and event-driven apps
* Standalone; no other gem dependencies
* `super_callbacks` is the upgraded version of my other repo [`dragonruby_callbacks`](https://github.com/jrpolidario/dragonruby_callbacks)
* Heavily influenced by [Rails' ActiveSupport::Callbacks](https://api.rubyonrails.org/classes/ActiveSupport/Callbacks.html)

## Dependencies

* **Ruby 2 or Ruby 3**

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'super_callbacks', '~> 1.3'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install super_callbacks

## Usage

### Example 1 (Block Mode)

```ruby
require 'super_callbacks'

class Foo
  # add this line inside your Class file/s
  include SuperCallbacks

  # add this block of lines
  before :bar do
    puts 'before bar!'
  end

  def bar
    puts 'bar!'
  end
end

foo = Foo.new
foo.bar
# => 'before bar!'
# => 'bar!'
```

*Notice above that the before block gets called first before the method `bar`*

```ruby
class Foo
  include SuperCallbacks

  after :bar do
    puts 'after bar!'
  end

  def bar
    puts 'bar!'
  end
end

foo = Foo.new
foo.bar
# => 'bar!'
# => 'after bar!'
```

*Notice above that the after block gets called after the method `bar`*

### Example 2 (Method Calling)

```ruby
class Foo
  include SuperCallbacks

  before :bar, :baz

  def bar
    puts 'bar!'
  end

  def baz
    puts 'baz!'
  end
end

foo = Foo.new
foo.bar
# => 'baz!'
# => 'bar!'
```

*Notice above that you can also call another method instead of supplying a block.*

*Above uses `before`, but works similarly with `after`*

### Example 3 (Multiple Callbacks)

```ruby
class Foo
  include SuperCallbacks

  before :bar, :baz_1
  before :bar do
    puts 'baz 2!'
  end
  before :bar, :baz_3

  def bar
    puts 'bar!'
  end

  def baz_1
    puts 'baz 1!'
  end

  def baz_3
    puts 'baz 3!'
  end
end

foo = Foo.new
foo.bar
# => 'baz 1!'
# => 'bar 2!'
# => 'bar 3!'
# => 'bar!'
```

*Notice above multiple callbacks are supported, and that they are called in first-come-first-served order.*

*Above uses `before`, but works similarly with `after`*

### Example 4 (Setter Method Callbacks)

> This is the primary reason why I made this: to handle "change-dependent" logic in my game engine

```ruby
class Foo
  include SuperCallbacks

  attr_accessor :bar

  before :bar= do |arg|
    puts "@bar currently has a value of #{@bar}"
    puts "@bar will have a new value of #{arg}"
  end

  before :baz do |arg1, arg2|
    puts "baz will be called with arguments #{arg1}, #{arg2}"
  end

  def baz(x, y)
    puts 'baz has been called!'
  end
end

foo = Foo.new
foo.bar = 5
# => '@bar currently has a value of '
# => '@bar will have a new value of 5'
puts foo.bar
# => 5

foo.baz(1, 2)
# => 'baz will be called with arguments 1, 2'
# => 'baz has been called!'
```

*Above uses `before`, but works similarly with `after`*

### Example 5 (Conditional Callbacks)

```ruby
class Monster
  include SuperCallbacks

  attr_accessor :hp

  after :hp=, :despawn, if: -> (arg) { @hp == 0 }

  # above is just equivalently:
  # after :hp= do |arg|
  #   despawn if @hp == 0
  # end

  def despawn
    puts 'despawning!'
    # do something here, like say removing the Monster from the world
  end
end

monster = Monster.new
monster.hp = 5
monster.hp -= 1 # 4
monster.hp -= 1 # 3
monster.hp -= 1 # 2
monster.hp -= 1 # 1
monster.hp -= 1 # hp is now 0, so despawn!
# => despawning!
```

*Above uses `after`, but works similarly with `before`*

### Example 6 (Pseudo-Skipping Callbacks)

* via Ruby's [`instance_variable_get`](https://ruby-doc.org/core-1.9.1/Object.html#method-i-instance_variable_get) and [`instance_variable_set`](https://ruby-doc.org/core-1.9.1/Object.html#method-i-instance_variable_set)

```ruby
class Foo
  include SuperCallbacks

  attr_accessor :bar

  before :bar= do |arg|
    puts 'before bar= is called!'
  end
end

foo = Foo.new

# normal way (callbacks are called):
foo.bar = 'somevalue'
# => 'before_bar= is called!'

# but to "pseudo" skip all callbacks, and directly manipulate the instance variable value:
foo.instance_variable_set(:@bar, 'somevalue')
```

*At the moment, I am not compelled (yet?) to fully support skipping callbacks because I do not want to pollute the DSL and I do not find myself yet needing such behaviour, because the callbacks are there for "integrity". If I really want the callbacks conditional, I'll just use the conditional argument.*

### Example 7 (Class and Instance Level Callbacks)

```ruby
class Foo
  include SuperCallbacks

  before :bar do
    puts 'before bar 1!'
  end

  before :bar do
    puts 'before bar 2!'
  end

  def bar
    puts 'bar!'
  end
end

foo_1 = Foo.new
foo_2 = Foo.new

foo_1.before :bar do
  puts 'before bar 3'
end

foo_1.before :bar do
  puts 'before bar 4'
end

foo_1.bar
# => 'before bar 1!'
# => 'before bar 2!'
# => 'before bar 3'
# => 'before bar 4'
# => 'bar!'

foo_2.bar
# => 'before bar 1!'
# => 'before bar 2!'
# => 'bar!'
```

*Notice above that foo_1 and foo_2 both call the class-level callbacks, while they have independent (not-shared) instance-level callbacks defined. Order of execution is class-level first then instance-level, of which defined callbacks are then in order of first-come-first-serve.*

*Above uses `before`, but works similarly with `after`*

### Example 8 (Inherited Callbacks)

```ruby
class Foo
  include SuperCallbacks

  before :bar do
    puts 'Foo: before bar 1!'
  end

  def bar
    puts 'bar!'
  end
end

class SubFoo < Foo
  before :bar do
    puts 'SubFoo: bar'
  end
end

foo = Foo.new
foo.bar
# => 'Foo: before bar 1!'
# => 'bar!'

sub_foo = SubFoo.new
sub_foo.bar
# => 'Foo: before bar 1!'
# => 'SubFoo: bar'
# => 'bar!'
```

*Notice above `sub_foo` calls both `before` callbacks defined in `Foo` and `SubFoo`, because SubFoo inherits from Foo. Callbacks are called in order of ancestors descending; meaning it starts calling the top-level ancestor superclass callbacks, and then calling its subclass callbacks, until it reaches the instance's class callbacks*

*Above uses `before`, but works similarly with `after`*

### Example 9 (Requiring Method To Be Defined)

```ruby
class Foo
  include SuperCallbacks

  after! :bar do
    puts 'after bar!'
  end

  def bar
    puts 'bar!'
  end
end
# => ArgumentError: `bar` is not or not yet defined for Foo

class Foo
  include SuperCallbacks

  def bar
    puts 'bar!'
  end

  after! :bar do
    puts 'after bar!'
  end
end
# => [NO ERRORS]
```

*From above, sometimes I noticed that I forgot to define a method! So the bang `!` version is just basically like `after` except that this raises an error if `method_name` is not defined or not yet defined (at the time `after!` is called). This works perfect with `attr_accesors` I normally put them at the top of the lines of a Class, and so I can now safely call `before!` or `after!` because I am sure that I already defined everything I needed to define. If I forgot something then, this `before!` would raise an error and alert me, and not silently failing. Helps debugging :)*

*Above uses `after!`, but works similarly with `before!`*

### Example 10 (Dirty Checking of Instance Variables Changes)

```ruby
class Foo
  include SuperCallbacks

  attr_accessor :bar

  after :bar= do |arg|
    puts 'original values of all instance attributes:'
    puts instance_variables_before_change

    puts 'original value:'
    puts instance_variable_before_change :@bar

    if instance_variable_changed? :@bar
      puts 'new value'
      @arg
    end
  end
end

foo = Foo.new
foo.bar = 1 # bar is changed from nil to 1
# => original values of all instance attributes:
# => {}
# => original value:
# => nil
# => new value:
# => 1
foo.bar = 1 # bar is not changed from 1 to 1
# => original values of all instance attributes:
# => { :@bar => 1 }
# => original value:
# => 1
```

*Notice above on the second time `foo.bar = 1` is called, "new value" was no longer "puts", because `@bar` didn't change from 1 to 1. You can only use `instance_variables_before_change`, `instance_variable_before_change` and `instance_variable_changed?` inside the `SuperCallbacks` cycle; otherwise you will get a `"You cannot call this method outside the SuperCallbacks cycle"` error.*

*Above uses `after!`, but works similarly with `before!`*

## TODOs
* when the need already arises, implement `around` (If you have ideas or want to help this part, please feel free to fork or send me a message! :)
* Without changing the DSL, try to find a better solution than current one to fix [this bug](https://github.com/jrpolidario/super_callbacks/issues/1). As it required me to write a bit of overhead code via `InheritancePrepender` module.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jrpolidario/super_callbacks. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Changelog

* [1.3.2 (2024-11-30)](https://github.com/jrpolidario/super_callbacks/compare/8ae5be07d44633b942e5751b076cc7f0cb824045...dce3b148d7ec26545fa98e4ea3c01adcc8cab107)
    * Bump support of ruby version to ~> 3.0
* [1.3.1 (2019-08-15)](https://github.com/jrpolidario/super_callbacks/commit/dcc71648d9be06074280c936add04b6b3f921e10)
    * [Fixed difficult bug: callbacks not in order when method defined in subclass and not in superclass when using inherited callbacks](https://github.com/jrpolidario/super_callbacks/issues/1)
    * Refactored a lot of code, and added slight overhead. I'm satisfied at the moment until I could find the best solution.
* 1.2.0 (2019-08-15)
    * [Fixed / Supported Nested "Dirty" Changes on nested callbacks for idempotency (Thread-safe)](https://github.com/jrpolidario/super_callbacks/blob/4e9284e1c6150c6d5da536766d51b4e635bb819d/spec/super_callbacks_spec.rb#L487)
    * Housecleaning: segregated super_callbacks.rb into multiple files.
    * Now puts "overriden" warning messages when `SuperCallbacks` is included to a class which already has methods conflicting `SuperCallback`'s DSL-methods.
* 1.1.2 (2019-08-14)
    * [Supported "dirty" checking of instance variable changes](#example-10-dirty-checking-of-instance-variables-changes)
* 1.0.3 (2019-08-12)
    * Cleaner code without explicitly calling `run_callbacks` anymore; done now because of ruby upgrade from 1.9 to 2.0+ which already supports `prepend`
    * Supported both class and instance level callbacks
    * Supported inherited callbacks
* v0.2.1 (2019-08-09) *From `dragonruby_callbacks`*
    * Fixed syntax errors for ruby 1.9.3; Fixed not supporting subclasses of Proc, String, or Symbol
* v0.2 (2019-08-08) *From `dragonruby_callbacks`*
    * Supported [conditional callbacks](#conditional-callbacks) with `:if`
* v0.1 (2019-08-07) *From `dragonruby_callbacks`*
    * Done all
