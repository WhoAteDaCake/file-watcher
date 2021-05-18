class Runner
  def initialize(
    @paths : Array(Path),
    @events : Array(String),
    @cmd : String,
    @args : Array(String),
    @timeout : Float32 | Nil,
    @on_start : Bool,
    @process : Process | Nil
  )

  end

  def run()
    puts "Running"
  end
end