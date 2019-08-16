RSpec.describe SuperCallbacks do
  it 'has a version number' do
    expect(SuperCallbacks::VERSION).not_to be nil
  end

  context 'before!' do
    it 'should raise error if method not defined' do
      expect do
        Class.new do
          include SuperCallbacks

          before! :bar, :say_hi_first

          def bar
          end

          def say_hi_first
            puts 'Hi'
          end
        end
      end.to raise_error ArgumentError

      expect do
        Class.new do
          include SuperCallbacks

          def bar
          end

          before! :bar, :say_hi_first

          def say_hi_first
            puts 'Hi'
          end
        end
      end.to_not raise_error
    end
  end

  context 'after!' do
    it 'should raise error if method not defined' do
      expect do
        Class.new do
          include SuperCallbacks

          after! :bar, :say_hi_first

          def bar
          end

          def say_hi_first
            puts 'Hi'
          end
        end
      end.to raise_error ArgumentError

      expect do
        Class.new do
          include SuperCallbacks

          def bar
          end

          after! :bar, :say_hi_first

          def say_hi_first
            puts 'Hi'
          end
        end
      end.to_not raise_error
    end
  end

  context 'before' do
    it 'should not raise error if method not defined' do
      expect do
        Class.new do
          include SuperCallbacks

          before :bar, :say_hi_first

          def say_hi_first
            puts 'Hi'
          end
        end
      end.to_not raise_error
    end
  end

  context 'after' do
    it 'should not raise error if method not defined' do
      expect do
        Class.new do
          include SuperCallbacks

          after :bar, :say_hi_first

          def say_hi_first
            puts 'Hi'
          end
        end
      end.to_not raise_error
    end
  end

  context 'run_callbacks' do
    it 'should run defined callbacks for that method' do
      klass = Class.new do
        include SuperCallbacks

        attr_accessor :test_string_sequence

        def initialize
          @test_string_sequence = []
        end

        # below is intentionally defined not in order, for sequence testing

        before :bar, :say_hi_first

        after :bar, :say_goodbye

        before :bar do
          @test_string_sequence << 'Hello'
        end

        after :bar do
          @test_string_sequence << 'Paalam'
        end

        def say_hi_first
          @test_string_sequence << 'Hi'
        end

        def say_goodbye
          @test_string_sequence << 'Goodbye'
        end

        def bar
          @test_string_sequence << 'bar is called'
          @bar
        end
      end

      instance = klass.new
      instance.bar

      expect(instance.test_string_sequence).to eq ['Hi', 'Hello', 'bar is called', 'Goodbye', 'Paalam']
    end
  end

  it 'supports conditional callbacks' do
    klass = Class.new do
      include SuperCallbacks

      attr_accessor :test_string_sequence, :baz
      attr_writer :bar

      def initialize
        @test_string_sequence = []
      end

      before :bar=, :do_a, if: lambda { |arg| arg == 'hooman' && @baz = true }
      before :bar=, :do_b, if: lambda { |arg| arg == 'hooman' && @baz = false }
      before :bar=, :do_c, if: lambda { |arg| arg == 'dooge' && @baz = true }
      before :bar=, if: lambda { |arg| arg == 'dooge' && @baz = true } do
        do_d
      end

      def do_a
        @test_string_sequence << 'a'
      end

      def do_b
        @test_string_sequence << 'b'
      end

      def do_c
        @test_string_sequence << 'c'
      end

      def do_d
        @test_string_sequence << 'd'
      end
    end

    instance = klass.new
    instance.baz = true
    instance.bar = 'dooge'

    expect(instance.test_string_sequence).to eq ['c', 'd']
  end

  context 'valid arguments subclasses' do
    it 'should be supported' do
      string_subclass = Class.new(String)

      klass = Class.new do
        include SuperCallbacks

        attr_accessor :test_string_sequence
        attr_reader :bar

        def initialize
          @test_string_sequence = []
        end

        before :bar, string_subclass.new('say_hi_first')

        def say_hi_first
          @test_string_sequence << 'Hi'
        end
      end

      instance = klass.new
      instance.bar

      expect(instance.test_string_sequence).to eq ['Hi']
    end
  end

  it 'supports inherited callbacks' do
    base_class = Class.new do
      include SuperCallbacks

      attr_accessor :test_string_sequence
      attr_reader :bar

      def initialize
        @test_string_sequence = []
      end

      before :bar, :say_hi_first

      def say_hi_first
        @test_string_sequence << 'Hi'
      end
    end

    sub_class = Class.new(base_class) do
    end

    instance = sub_class.new
    instance.bar

    expect(instance.test_string_sequence).to eq ['Hi']
  end

  it 'supports instance callbacks' do
    klass = Class.new do
      include SuperCallbacks

      attr_accessor :test_string_sequence
      attr_accessor :bar

      def initialize
        @test_string_sequence = []
      end
    end

    instance_1 = klass.new
    instance_1.before :bar= do |arg|
      @test_string_sequence << "Hi #{arg}"
    end

    instance_2 = klass.new

    instance_1.bar = 2
    instance_2.bar = 3

    expect(instance_1.test_string_sequence).to eq ['Hi 2']
    expect(instance_2.test_string_sequence).to eq []
  end

  it 'supports inherited + instance callbacks' do
    base_class = Class.new do
      include SuperCallbacks

      attr_accessor :test_string_sequence
      attr_writer :bar

      def initialize
        @test_string_sequence = []
      end

      before :bar= do |arg|
        @test_string_sequence << "Hello #{arg}"
      end

      after :bar= do |arg|
        @test_string_sequence << "Konnichi wa #{arg}"
      end
    end

    sub_class = Class.new(base_class) do
    end

    instance_1 = sub_class.new
    instance_1.before :bar= do |arg|
      @test_string_sequence << "Hi #{arg}"
    end

    instance_1.after :bar= do |arg|
      @test_string_sequence << "Kumusta #{arg}"
    end

    instance_2 = sub_class.new

    instance_1.bar = 2
    instance_2.bar = 3

    expect(instance_1.test_string_sequence).to eq ['Hello 2', 'Hi 2', 'Konnichi wa 2', 'Kumusta 2']
    expect(instance_2.test_string_sequence).to eq ['Hello 3', 'Konnichi wa 3']
  end

  it 'returns original value of method' do
    klass = Class.new do
      include SuperCallbacks

      before :bar, :say_hi_first

      def bar
        'bar'
      end

      def say_hi_first
        'Hi'
      end
    end

    instance = klass.new

    expect(instance.bar).to eq 'bar'
  end

  it 'prevents being re-included to a Class' do
    klass = Class.new do
      include SuperCallbacks
      include SuperCallbacks
      include SuperCallbacks
      include SuperCallbacks
      include SuperCallbacks
    end

    super_callbacks_prepended_modules = klass.ancestors.select { |ancestor| ancestor.is_a? SuperCallbacks::Prepended }
    expect(super_callbacks_prepended_modules.size).to eq 1
  end

  it 'runs the callbacks in correct order when the method is defined in the subclass' do
    # skip 'All attempts so far failed. Not a priority at the moment; so I will come back into this, or if you have any ideas, feel free to let me know or submit a merge request! :)'

    base_class = Class.new do
      include SuperCallbacks

      attr_accessor :test_string_sequence

      def initialize
        @test_string_sequence = []
      end

      before :bar, :say_hi_first
      after :bar, :say_goodbye

      def bar
        @test_string_sequence << 'bar'
      end

      def say_hi_first
        @test_string_sequence << 'Hi'
      end

      def say_goodbye
        @test_string_sequence << 'Goodbye'
      end
    end

    sub_class = Class.new(base_class) do
      def bar
        @test_string_sequence << 'sub class'
        # super
      end
    end

    sub_sub_class = Class.new(sub_class) do
      def bar
        @test_string_sequence << 'sub sub class'
        # super
      end
    end

    instance = sub_sub_class.new
    instance.bar

    expect(instance.test_string_sequence).to eq ['Hi', 'sub sub class', 'sub class', 'bar', 'Goodbye']
  end

  context 'after' do
    it 'supports dirty checking of "changes" of instance variables values' do
      klass = Class.new do
        include SuperCallbacks

        attr_accessor :test_string_sequence
        attr_accessor :bar

        def initialize
          @test_string_sequence = []
        end

        after :bar=, :say_hi_first

        def say_hi_first
          if instance_variable_changed? :@bar
            @test_string_sequence << 'Hi'
          end
        end
      end

      instance = klass.new

      instance.bar = 1 # changed from nil to 1
      expect(instance.test_string_sequence).to eq ['Hi']

      instance.bar = 1 # not changed from 1 to 1
      expect(instance.test_string_sequence).to eq ['Hi']

      instance.bar = 2 # changed from 1 to 2
      expect(instance.test_string_sequence).to eq ['Hi', 'Hi']
    end
  end

  context 'before' do
    it 'supports dirty checking of "changes" of instance variables values' do
      klass = Class.new do
        include SuperCallbacks

        attr_accessor :test_string_sequence
        attr_accessor :bar, :baz

        def initialize
          @test_string_sequence = []
          @baz = 0
        end

        before :bar= do |arg|
          if arg == true
            self.baz += 1
          end
        end

        before :bar= do |arg|
          if instance_variable_changed? :@bar
            @test_string_sequence << 'Hi'
          end

          if instance_variable_changed? :@baz
            @test_string_sequence << 'Hello'
          end
        end
      end

      instance = klass.new

      instance.bar = 1
      # changed bar from nil to 1
      #   but instance_variable_changed? :@bar would return false, because it's `before' hook`
      # not changed baz from 0 to 0
      expect(instance.test_string_sequence).to eq []

      instance.bar = 1
      # not changed bar from nil to nil
      # not changed baz from 0 to 0
      expect(instance.test_string_sequence).to eq []

      instance.bar = true
      # changed bar from nil to true
      #   but instance_variable_changed? :@bar would return false, because it's `before' hook`
      # changed baz from 0 to 1
      expect(instance.test_string_sequence).to eq ['Hello']

      instance.bar = true
      # not changed bar from true to true
      # changed baz from 1 to 2
      expect(instance.test_string_sequence).to eq ['Hello', 'Hello']
    end
  end

  context 'before' do
    it 'tracks "changes" independently of callbacks when nestedly called' do
      klass = Class.new do
        include SuperCallbacks

        # need this to be a class instance variable to test, otherwise expected StackLevel error
        @test_string_sequence = []
        singleton_class.send(:attr_accessor, :test_string_sequence)

        attr_accessor :bar, :baz

        def initialize
          @bar = 0
        end

        after :bar= do |arg|
          self.baz = 1
          self.class.test_string_sequence << instance_variables_before_change
        end

        after :baz= do |arg|
          self.class.test_string_sequence << instance_variables_before_change
        end
      end

      instance = klass.new

      instance.bar = true
      # changed bar from nil to true
      # which triggers baz= callback
      # then after baz= finished, it goes back to the after :bar=
      expect(instance.class.test_string_sequence).to eq [
        { :@bar => true },
        { :@bar => 0 }
      ]

      expect(Thread.current[:super_callbacks_all_instance_variables_before_change]).to be nil
    end
  end

  it 'puts warning message when SuperCallback instance methods already defined to prevent unexpected weird behaviours' do
    klass = Class.new

    expect do
      klass.class_eval do
        def before
        end

        def instance_variables_before_change
        end

        include SuperCallbacks
      end
    end.to output("WARN: SuperCallbacks will override #{klass} the following already existing instance methods: " \
      "[:before, :instance_variables_before_change]\n"
    ).to_stdout
  end

  it 'puts warning message when SuperCallback class methods already defined to prevent unexpected weird behaviours' do
    klass = Class.new

    expect do
      klass.class_eval do
        def self.before
        end

        def self.callbacks_prepended_module_instance
        end

        include SuperCallbacks
      end
    end.to output("WARN: SuperCallbacks will override #{klass} the following already existing class methods: " \
      "[:before, :callbacks_prepended_module_instance]\n"
    ).to_stdout
  end
end
