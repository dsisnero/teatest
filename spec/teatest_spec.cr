require "./spec_helper"

class ErrorReader < IO
  def read(slice : Bytes) : Int32
    raise IO::Error.new("fake")
  end

  def write(slice : Bytes) : Nil
  end

  def close : Nil
  end

  def closed? : Bool
    false
  end
end

describe Teatest do
  it "wait_for returns error on reader failure" do
    error = expect_raises(Exception) do
      Teatest.wait_for(ErrorReader.new, ->(_b : Bytes) { true }, [
        Teatest.with_duration(1.millisecond),
        Teatest.with_check_interval(10.microseconds),
      ])
    end
    error.message.should eq "WaitFor: fake"
  end

  it "wait_for returns timeout error" do
    error = expect_raises(Exception) do
      Teatest.wait_for(IO::Memory.new("nope"), ->(_b : Bytes) { false }, [
        Teatest.with_duration(1.millisecond),
        Teatest.with_check_interval(10.microseconds),
      ])
    end
    error.message.should eq "WaitFor: condition not met after 1ms. Last output:\nnope"
  end

  it "wait_finished with timeout fn triggers" do
    tm = Teatest.new_test_model(M.new("a"))
    begin
      timed_out = false
      tm.wait_finished([
        Teatest.with_final_timeout(1.nanosecond),
        Teatest.with_timeout_fn(->(_tb : Teatest::TB) { timed_out = true }),
      ])
      timed_out.should be_true
    ensure
      tm.quit
    end
  end

  it "with_program_options allows options but teatest options override" do
    tm = Teatest.new_test_model(M.new("a"), [
      Teatest.with_program_options(Tea.with_window_size(1, 1)),
      Teatest.with_initial_term_size(70, 30),
    ])
    begin
      tm.program.width.should eq 70
      tm.program.height.should eq 30
    ensure
      tm.quit
    end
  end

  it "get_program returns underlying program" do
    tm = Teatest.new_test_model(M.new("a"))
    begin
      tm.get_program.should be(tm.program)
    ensure
      tm.quit
    end
  end
end

struct M
  include Bubbletea::Model

  def initialize(@value : String)
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    {self, nil}
  end

  def view : Bubbletea::View
    Bubbletea::View.new(@value)
  end
end
