require "bubbletea"
require "golden"

module Teatest
  VERSION = "0.1.0"

  # Program defines the subset of the Bubble Tea program API we need for testing.
  module Program
    abstract def send(msg : Tea::Msg)
  end

  # TestModelOptions defines all options available to the test function.
  class TestModelOptions
    property size : Bubbletea::WindowSizeMsg
    property program_opts : Array(Bubbletea::ProgramOption)

    def initialize
      @size = Bubbletea::WindowSizeMsg.new(0, 0)
      @program_opts = [] of Bubbletea::ProgramOption
    end
  end

  # TestOption is a functional option.
  alias TestOption = Proc(TestModelOptions, Nil)

  # WithInitialTermSize sets the initial terminal size.
  def self.with_initial_term_size(x : Int32, y : Int32) : TestOption
    ->(opts : TestModelOptions) {
      opts.size = Bubbletea::WindowSizeMsg.new(x, y)
    }
  end

  # WithProgramOptions adds Bubble Tea ProgramOptions to the test model.
  def self.with_program_options(*options : Bubbletea::ProgramOption) : TestOption
    ->(opts : TestModelOptions) {
      opts.program_opts = options.to_a
    }
  end

  # WaitingForContext is the context for a WaitFor.
  class WaitingForContext
    property duration : Time::Span
    property check_interval : Time::Span

    def initialize
      @duration = 1.second
      @check_interval = 50.milliseconds
    end
  end

  # WaitForOption changes how a WaitFor will behave.
  alias WaitForOption = Proc(WaitingForContext, Nil)

  # WithCheckInterval sets how much time a WaitFor should sleep between every check.
  def self.with_check_interval(d : Time::Span) : WaitForOption
    ->(wf : WaitingForContext) { wf.check_interval = d }
  end

  # WithDuration sets how much time a WaitFor will wait for the condition.
  def self.with_duration(d : Time::Span) : WaitForOption
    ->(wf : WaitingForContext) { wf.duration = d }
  end

  # WaitFor keeps reading from r until the condition matches.
  # Default duration is 1s, default check interval is 50ms.
  def self.wait_for(r : IO, condition : Bytes -> Bool, options : Array(WaitForOption) = [] of WaitForOption) : Nil
    if err = do_wait_for(r, condition, options)
      raise err
    end
  end

  private def self.do_wait_for(r : IO, condition : Bytes -> Bool, options : Array(WaitForOption)) : Exception?
    wf = WaitingForContext.new
    options.each(&.call(wf))

    buffer = IO::Memory.new
    chunk = Bytes.new(4096)
    start = Time.instant

    while (Time.instant - start) <= wf.duration
      begin
        while (n = r.read(chunk)) > 0
          buffer.write(chunk[0, n])
        end
      rescue ex
        return Exception.new("WaitFor: #{ex.message}", cause: ex)
      end

      if condition.call(buffer.to_slice)
        return
      end

      sleep wf.check_interval
    end

    Exception.new("WaitFor: condition not met after #{format_duration(wf.duration)}. Last output:\n#{buffer}")
  end

  private def self.format_duration(duration : Time::Span) : String
    ms = duration.total_milliseconds
    return "#{ms.to_i}ms" if ms < 1000

    s = duration.total_seconds
    return "#{s.to_i}s" if s == s.to_i

    secs = s.round(3).to_s
    secs = secs.gsub(/\.0+$/, "")
    secs = secs.gsub(/(\.\d*?)0+$/, "\\1")
    "#{secs}s"
  end

  # FinalOpts represents the options for FinalModel and FinalOutput.
  class TB
    def fatal(message : String) : NoReturn
      raise message
    end
  end

  class FinalOpts
    property timeout : Time::Span
    property on_timeout : Proc(TB, Nil)?

    def initialize
      @timeout = 0.seconds
      @on_timeout = nil
    end
  end

  # FinalOpt changes FinalOpts.
  alias FinalOpt = Proc(FinalOpts, Nil)

  # WithTimeoutFn allows to define what happens when WaitFinished times out.
  def self.with_timeout_fn(fn : Proc(TB, Nil)) : FinalOpt
    ->(opts : FinalOpts) { opts.on_timeout = fn }
  end

  # WithFinalTimeout allows to set a timeout for how long FinalModel and FinalOutput should wait.
  def self.with_final_timeout(d : Time::Span) : FinalOpt
    ->(opts : FinalOpts) { opts.timeout = d }
  end

  # TestModel is a model that is being tested.
  class TestModel
    include Program

    getter program : Bubbletea::Program

    @in : IO::Memory
    @out : SafeReadWriter
    @model_ch : Channel(Bubbletea::Model?)
    @model : Bubbletea::Model?
    @done_ch : Channel(Bool)
    @done : Bool
    @done_mutex : Mutex
    @run_err : Exception?

    def initialize(@program : Bubbletea::Program, @in : IO::Memory, @out : SafeReadWriter)
      @model_ch = Channel(Bubbletea::Model?).new(1)
      @done_ch = Channel(Bool).new(1)
      @done = false
      @done_mutex = Mutex.new
      @model = nil
      @run_err = nil
    end

    # WaitFinished waits for the app to finish.
    def wait_finished(opts : Array(FinalOpt) = [] of FinalOpt) : Nil
      wait_done(opts)
    end

    # FinalModel returns the resulting model from program.run.
    def final_model(opts : Array(FinalOpt) = [] of FinalOpt) : Bubbletea::Model?
      wait_done(opts)
      if model = @model_ch.receive?
        @model = model
      end
      @model
    end

    # FinalOutput returns the program's final output io.Reader.
    def final_output(opts : Array(FinalOpt) = [] of FinalOpt) : IO
      wait_done(opts)
      output
    end

    # Output returns the program's current output io.Reader.
    def output : IO
      @out
    end

    # Send sends messages to the underlying program.
    def send(msg : Tea::Msg) : Nil
      @program.send(msg)
    end

    # Send accepts any value and wraps non-Msg values like Go's tea.Msg (interface{}).
    def send(value) : Nil
      @program.send(Tea.wrap(value))
    end

    # Quit quits the program and releases the terminal.
    def quit : Nil
      @program.quit
    end

    # Type types the given text into the given program.
    def type(s : String) : Nil
      s.each_char do |char|
        @program.send(Tea.key(char))
        Fiber.yield
      end
    end

    protected def send_done(model : Bubbletea::Model?, err : Exception?) : Nil
      @run_err = err if err
      @model_ch.send(model)
      @done_ch.send(true)
    end

    private def wait_done(opts : Array(FinalOpt)) : Nil
      should_wait = false
      @done_mutex.synchronize do
        unless @done
          @done = true
          should_wait = true
        end
      end
      return unless should_wait

      fopts = FinalOpts.new
      opts.each(&.call(fopts))

      if fopts.timeout > 0.seconds
        select
        when timeout(fopts.timeout)
          if on_timeout = fopts.on_timeout
            on_timeout.call(TB.new)
          else
            raise "timeout after #{fopts.timeout}"
          end
        when @done_ch.receive
        end
      else
        @done_ch.receive
      end

      if run_err = @run_err
        raise run_err
      end
    end
  end

  # NewTestModel makes a new TestModel which can be used for tests.
  def self.new_test_model(m : Bubbletea::Model, options : Array(TestOption) = [] of TestOption) : TestModel
    input = IO::Memory.new
    output = SafeReadWriter.new(IO::Memory.new)

    # Match Go v2 teatest: always start with an initial size unless overridden.
    options = [with_initial_term_size(80, 24)] + options

    opts = TestModelOptions.new
    options.each(&.call(opts))

    program = Bubbletea::Program.new(m)
    opts.program_opts.each(&.call(program))
    Tea.with_input(input).call(program)
    Tea.with_output(output).call(program)
    Tea.without_signals.call(program)
    Tea.with_window_size(opts.size.width, opts.size.height).call(program)

    tm = TestModel.new(program, input, output)

    Process.on_terminate do
      tm.program.kill
    end

    spawn do
      model, err = program.run
      tm.send_done(model, err)
    end

    if opts.size.width != 0
      program.send(opts.size)
    end

    tm
  end

  # RequireEqualOutput asserts the given output matches golden files.
  def self.require_equal_output(test_name : String, output : Bytes) : Nil
    test_data_dir = Golden.spec_test_data_dir || "spec/testdata"
    Golden.require_equal(test_name, output, test_data_dir)
  end

  class SafeReadWriter < IO
    @rw : IO::Memory
    @lock : Mutex
    @read_pos : Int32 = 0

    def initialize(@rw : IO::Memory)
      @lock = Mutex.new
    end

    def read(slice : Bytes) : Int32
      @lock.synchronize do
        data = @rw.to_slice
        remaining = data.size - @read_pos
        return 0 if remaining <= 0

        n = Math.min(slice.size, remaining)
        slice.copy_from(data[@read_pos, n])
        @read_pos += n
        n
      end
    end

    def write(slice : Bytes) : Nil
      @lock.synchronize { @rw.write(slice) }
    end

    def flush : Nil
      @lock.synchronize { @rw.flush }
    end

    def close : Nil
      @lock.synchronize { @rw.close }
    end

    def closed? : Bool
      @rw.closed?
    end
  end
end
