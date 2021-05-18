require "admiral"
require "./runner"

ALLOWED_EVENTS = ["modify", "moved_to", "moved_from", "move", "create", "delete"]

class Command < Admiral::Command
  define_version "1.0.0"
  define_help description: "File watching utility built on inotify-tools"

  define_flag on_start : Bool,
    description: "Run command on watcher start",
    long: "on-start",
    short: "x",
    default: false
    
  define_flag all_events : Bool,
    description: "Watch for all events",
    long: "all-events",
    short: "a",
    default: false

  define_flag dirs : Array(String),
    description: "Watch for all events",
    long: "dir",
    short: "d",
    required: true

  define_flag timeout : Float32,
    description: "How long should we wait from event to start of action",
    long: "timeout",
    short: "t"

  define_flag events : Array(String),
    description: "Event to watch for, one of: #{ALLOWED_EVENTS.join(", ")}",
    long: "event",
    short: "e"

  class Execute < Admiral::Command
    def run
      args = @argv.map { |s| s.value }
      if args.size < 1
        abort("Expected a command to follow the executable")
      end
      pf = parent.flags.as(Command::Flags)

      # Event verification
      events =
        if pf.all_events
          ALLOWED_EVENTS
        else
          pf.events
        end
      
      if events.size == 0 
        abort("Expected at least 1 event to listen for, found none")
      end

      unexpected = events - ALLOWED_EVENTS
      if unexpected.size != 0
        abort("Unexpected events found: #{unexpected.join(", ")}")
      end
      
      # Directory verification
      if pf.dirs.size == 0
        abort("Expected at least 1 directory to watch, found none")
      end

      paths = pf.dirs.map { |d| Path[d].normalize.expand(home: true) }
      unexpected = paths.select { |p| ! Dir.exists?(p) }
      if unexpected.size != 0
        abort("Could not find directories:\n\t- #{unexpected.join("\n\t- ")}")
      end
    
      # Command
      cmd = Process.find_executable(args[0])
      if cmd.nil?
        abort("Could not find executable: #{args[0]}")
      end
      args.shift
      
      runner = Runner.new(
        paths,
        events,
        cmd,
        args,
        pf.timeout,
        pf.on_start,
        nil
      )
      runner.run
    end
  end
  
  register_sub_command execute : Execute,
    description: "Execute the following command"

  def run
    puts help
  end
end

# Command.run "--help"
Command.run "--on-start --dir ./test -a execute bash -c hello"
