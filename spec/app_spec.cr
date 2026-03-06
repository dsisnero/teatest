require "./spec_helper"

describe "Teatest app" do
  it "runs a program and captures output" do
    model = CountdownModel.new(10)
    tm = Teatest.new_test_model(model, [Teatest.with_initial_term_size(70, 30)])
    begin
      sleep 1.2.seconds
      tm.type("I'm typing things, but it'll be ignored by my program")
      tm.send("ignored msg")
      tm.send(Tea.key(Tea::KeyEnter))

      tm.quit

      output = read_bytes(tm.final_output([Teatest.with_final_timeout(1.second)]))
      output_str = String.new(output)
      output_str.should match(/This program will exit in \d+ seconds/)
      Teatest.require_equal_output("TestApp", output)

      final_model = tm.final_model
      final_model.should_not be_nil
      if model = final_model
        model.as(CountdownModel).value.should eq 9
      else
        fail "expected final model"
      end
    ensure
      tm.quit
    end
  end

  it "supports interactive output inspection" do
    model = CountdownModel.new(10)
    tm = Teatest.new_test_model(model, [Teatest.with_initial_term_size(70, 30)])
    begin
      sleep 1.2.seconds
      tm.send("ignored msg")

      output = read_bytes(tm.output)
      String.new(output).should contain("9 seconds")

      Teatest.wait_for(tm.output, ->(buffer : Bytes) { buffer.includes?('7'.ord.to_u8) }, [
        Teatest.with_duration(5.seconds),
        Teatest.with_check_interval(10.milliseconds),
      ])

      tm.send(Tea.key(Tea::KeyEnter))
      tm.quit

      final_model = tm.final_model
      final_model.should_not be_nil
      if model = final_model
        model.as(CountdownModel).value.should eq 7
      else
        fail "expected final model"
      end
    ensure
      tm.quit
    end
  end
end

struct CountdownModel
  include Bubbletea::Model

  getter value : Int32

  def initialize(@value : Int32)
  end

  def init : Bubbletea::Cmd?
    -> : Tea::Msg? {
      sleep 1.second
      TickMsg.new
    }
  end

  def update(msg : Tea::Msg)
    case msg
    when Tea::Key
      {self, Tea.quit}
    when TickMsg
      @value -= 1
      if @value <= 0
        {self, Tea.quit}
      else
        {self, init}
      end
    else
      {self, nil}
    end
  end

  def view : Bubbletea::View
    Bubbletea::View.new("Hi. This program will exit in #{@value} seconds. To quit sooner press any key.\n")
  end
end

struct TickMsg
  include Tea::Msg
end
