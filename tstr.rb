module Tstr
  class DoesNotMatch < RuntimeError; end
  class Element < Struct.new(:desc, :block); end

  class Group
    attr_reader :klass, :children, :vals
    def initialize(klass, lets, children)
      @klass, @children = klass, children
      @vals = lets.map { |(k, v)| [k, v.call] }.to_h
    end
  end

  class ElCtx < Struct.new(:_group)
    def expect(v); Expectation.new(v); end
    def method_missing(name, *args)
      _group.vals[name] || MATCHERS[name].call(*args) || super
    end
  end

  class DSL < Struct.new(:_groups)
    def describe(kl, &block)
      _groups << GroupBuilder.new(kl, block).build
    end
  end

  class GroupBuilder
    class DSL < Struct.new(:builder)
      def let(sym, &block); builder.add_let(sym, block); end
      def it(desc, &block); builder.add_it(desc, block); end
    end

    def initialize(klass, block)
      @klass, @block, @lets, @its = klass, block, {}, []
    end

    def add_let(sym, block); @lets[sym] = block; end
    def add_it(desc, block); @its << Element.new(desc, block); end

    def build
      DSL.new(self).instance_eval(&@block)
      Group.new(@klass, @lets, @its)
    end
  end

  class DefaultReporter
    def initialize; @green, @red = 0, 0; end

    def report_green(ctx)
      @green += 1 and puts "#{ctx} - passes"
    end

    def report_red(ctx)
      @red += 1 and puts "#{ctx} - fails"
    end

    def finalize
      puts
      puts "#{@green + @red} samples: #{@green} passed, #{@red} failed"
    end
  end

  class Runner < Struct.new(:groups, :reporter)
    def run
      groups.each do |group|
        el_ctx = ElCtx.new(group)
        group.children.each do |el|
          ctx = [group.klass.name.to_s, el.desc].join(' - ')
          begin
            el_ctx.instance_eval(&el.block)
            reporter.report_green(ctx)
          rescue DoesNotMatch
            reporter.report_red(ctx)
          end
        end
      end

      reporter.finalize
    end
  end

  class Loader < Struct.new(:fname)
    def run
      w = []
      DSL.new(w).instance_eval IO.read(fname), fname
      Runner.new(w, DefaultReporter.new).run
    end
  end

  class Expectation < Struct.new(:val)
    def to(matcher)
      raise DoesNotMatch unless matcher.call(val)
    end
  end

  MATCHERS = {
    eq: ->(v) { ->(val) { v == val } }
  }
end

Tstr::Loader.new(ARGV[0]).run
