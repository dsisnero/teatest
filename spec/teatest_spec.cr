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

  describe "golden wrappers" do
    describe "show_snapshot" do
      it "returns nil for missing snapshot" do
        Teatest.show_snapshot("nonexistent.golden").should be_nil
      end

      it "returns content for existing snapshot" do
        existing = Dir.glob("spec/testdata/*.golden").first
        Teatest.show_snapshot(existing).should_not be_nil
      end
    end

    describe "test_and_review!" do
      it "raises when the spec command fails" do
        error = expect_raises(Exception) do
          Teatest.test_and_review!("false")
        end
        error.message.should eq "spec command 'false' failed with exit code 1"
      end

      it "returns pending snapshots after a passing command" do
        with_pending_snapshot do |dir, pending_path|
          Teatest.test_and_review!("true", dir).should eq [pending_path]
        end
      end
    end

    describe "review!" do
      it "returns empty when no pending snapshots" do
        Golden.cleanup! # clean any stale pending files
        Teatest.review!.should be_empty
      end

      it "returns and prints pending snapshots" do
        with_pending_snapshot do |dir, pending_path|
          io = IO::Memory.new
          Teatest.review!(dir, io).should eq [pending_path]
          io.to_s.should contain "1 pending snapshot(s) found:"
          io.to_s.should contain pending_path
        end
      end
    end
  end
end

# Yields an empty snapshot directory containing one pending `*.golden.new`
# file, along with the pending path. The directory is removed afterwards.
def with_pending_snapshot(&)
  dir = File.join(Dir.tempdir, "teatest-review-#{Process.pid}-#{Random.rand(1_000_000)}")
  FileUtils.mkdir_p(dir)
  pending_path = File.join(dir, "Sample.golden.new")
  File.write(pending_path, "pending\n")
  begin
    yield dir, pending_path
  ensure
    FileUtils.rm_rf(dir)
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
