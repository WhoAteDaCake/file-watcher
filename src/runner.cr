require "inotify"
require "./constants"

class Runner
  def initialize(
    @paths : Array(Path),
    @events : Array(String),
    @command_name : (String),
    @cmd : String,
    @args : Array(String),
    @timeout : Float64,
    @on_start : Bool,
    @process : Process | Nil
  )
  end

  def spawn_process(cmd, args)
    out_read, out_write = IO.pipe
    err_read, err_write = IO.pipe
    proc = Process.new(
      cmd,
      args,
      input: Process::Redirect::Close,
      output: out_write,
      error: err_write
    )

    spawn do
      until out_read.closed?
        line = out_read.gets(chomp: false)
        if line.nil?
          break
        end
        STDOUT.printf("[%s] %s", @command_name, line)
      end
    end

    # STDERR
    spawn do
      until err_read.closed?
        line = err_read.gets(chomp: false)
        if line.nil? 
          break
        end
        STDERR.printf("[%s] %s", @command_name, line)
      end
    end

    spawn do
      while !proc.terminated?
        sleep 1
      end
      STDOUT.printf("[%s] Terminated\n", @command_name)
    end
    proc
  end

  def run()
    mask = Constants::LOOKUP[@events.shift]
    mask = @events.reduce(mask) { |m, key| m | Constants::LOOKUP[key] } 

    watcher = Inotify::Watcher.new(true)
    @paths.each do | path |
      watcher.watch(path.to_s, mask)
    end 

    p! @args
    
    watcher.on_event do | e |
      # p! e
    end

    if @on_start
      @process = spawn_process(@cmd, @args)
    end

    while true
      sleep 10.seconds
    end
  end
end