require "./spec_helper"

describe "Teatest send" do
  it "sends messages between programs" do
    m1 = ConnectedModel.new("m1")
    m2 = ConnectedModel.new("m2")

    tm1 = Teatest.new_test_model(m1, [Teatest.with_initial_term_size(70, 30)])
    tm2 = Teatest.new_test_model(m2, [Teatest.with_initial_term_size(70, 30)])
    begin
      m1.programs << tm2
      m2.programs << tm1

      tm1.type("pp")
      tm2.type("pppp")

      tm1.type("q")
      tm2.type("q")

      out1 = read_bytes(tm1.final_output([Teatest.with_final_timeout(1.second)]))
      out2 = read_bytes(tm2.final_output([Teatest.with_final_timeout(1.second)]))

      out1.should eq out2
      Teatest.require_equal_output("TestAppSendToOtherProgram", out1)
    ensure
      tm1.quit
      tm2.quit
    end
  end
end

class ConnectedModel
  include Bubbletea::Model

  property programs : Array(Teatest::Program)
  @msgs : Array(String)

  def initialize(@name : String)
    @programs = [] of Teatest::Program
    @msgs = [] of String
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Tea::Key
      case msg.string
      when "p"
        ping = Ping.new("from #{@name}")
        @msgs << ping.value
        @programs.each(&.send(ping))
        puts %(sent ping "#{ping.value}" to others)
      when "q"
        return {self.as(Bubbletea::Model), Tea.quit}
      end
    when Ping
      puts %(rcvd ping "#{msg.value}" on #{@name})
      @msgs << msg.value
    end
    {self.as(Bubbletea::Model), nil}
  end

  def view : Bubbletea::View
    Bubbletea::View.new("All pings:\n" + @msgs.join("\n"))
  end
end

struct Ping
  include Tea::Msg

  getter value : String

  def initialize(@value : String)
  end
end
