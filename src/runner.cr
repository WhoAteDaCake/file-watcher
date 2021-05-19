require "inotify"
require "./constants"

def now_clean()
  Time.local.to_s("%Y-%m-%d %H:%M:%S")
end

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
      STDOUT.printf("[%s] TERMINATED (%s)\n", @command_name, now_clean)
    end
    proc
  end

  def run()
    mask = Constants::LOOKUP[@events.shift]
    mask = @events.reduce(mask) { |m, key| m | Constants::LOOKUP[key] } 

    time_channel = Channel(Time).new
    watcher = Inotify::Watcher.new(true)
    @paths.each do | path |
      watcher.watch(path.to_s, mask)
    end 

    watcher.on_event do | e |
      time_channel.send(Time.utc)
    end
    
    last_spawn = nil
    if @on_start
      last_spawn = Time.utc
      @process = spawn_process(@cmd, @args)
    end

    loop do
      slot = time_channel.receive
      process = @process
      if last_spawn.is_a?(Time)
        change = Time.utc - last_spawn
        change = change.total_seconds
        if change < @timeout
          # Skipping
          if process.is_a?(Process) && !process.terminated?
            next
          end
        end
      end
      # 
      if process.is_a?(Process) && !process.terminated?
        process.terminate
        process.wait
      end
      last_spawn = Time.utc
      @process = spawn_process(@cmd, @args)
    end
  end
end