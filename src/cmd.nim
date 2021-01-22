import docopt
include state
import strformat

let allowedEvents = @["modify", "move_to", "moved_from", "move", "create", "delete"]

const doc = """
File watcher utility

Usage:
  fwatcher (--dir <dir>)... ((--event <event>)... | --all-events) -- <action>...

Options:
  -d <dir>, --dir <dir>         Directory to listen to
  -e <event>, --event <event>   Event to watch for, one of:
                                  modify, move_to, moved_from, move, create, delete
  --all-events                  Listen to all events above
  <action>                      Action to perform on file change
"""

proc parse_args(): State =
  let args = docopt(doc, version = "File watcher 1.0")
  var events = @(args["--event"])
  if args["--all-events"]:
    events = allowedEvents
  else:
    # Validate events
    for ev in events:
      if not allowedEvents.contains(ev):
        raise newException(Exception, fmt"Unexpected event [{ev}]")

  return State(
    dirs: @(args["--dir"]),
    events: events,
    action: @(args["<action>"])
  )