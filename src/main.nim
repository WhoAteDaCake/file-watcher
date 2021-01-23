import strformat
import pipe
import osproc
import sequtils
import streams
import algorithm
import strutils

import zero_functional, unpack, options

include cmd

proc parseLine(line: string): (string, string, string) =
  let parts = line.split(' ')
  [*path_parts, event, time] <- parts
  let path = foldr(path_parts, a & b)
  return (path, event, time)

proc which(command: string): string =
  return execProcess(fmt"which {command}")[0 .. ^2]

proc event_loop(watcher: Process, action: seq[string]): void =
  let stream = outputStream(watcher)
  var lastTime = none(string)
  var lastProc = none(Process)
  # See, what's the path to executable
  [actionCmd, *actionArgs] <- action
  let command = which(actionCmd)
  # Primary loop
  var line = ""
  while stream.readLine(line):
    let (path, event, time) = parseLine(line)
    # inotifywait creates two rows for each change
    # probably a bug
    if lastTime.isSome and lastTime.get() == time:
      continue
    echo(fmt"{path} {event} {time}")
    # Process still running, kill it
    if lastProc.isSome and lastProc.get().running:
      echo("Killing previous process")
      lastProc.get().terminate()
      lastProc.get().close()
    let newAction = map(actionArgs, proc  (arg: string): string = 
      if arg == "%p":
        path
      elif arg == "%e":
        event.toLower()
      else:
        arg
    )
    echo("Starting new process")
    let newProc = startProcess(command, "", newAction, nil, {poParentStreams})
    lastProc = some(newProc)
    lastTime = some(time)

# inotifywait -m -r --format '%w %e %T' --timefmt '%s'

let watcher = "inotifywait"
let default_args = @["-m", "-r", "--format", "%w%f %e %T", "--timefmt", "%s"]

proc setup(state: State) =
  let events = state.events.zFun:
    map(@["-e", it])
    flatten()
  # Combine arguments
  let all_args = concat(default_args, events, state.dirs)
  # Start primary watcher
  echo("Starting watcher loop")
  startProcess(which(watcher), "", all_args, nil, {})
    .event_loop(state.action)


parse_args() |> setup