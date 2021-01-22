let doc = """
File watcher utility

Usage:
  fwatcher (--dir=<dir>)... (--event=<event>)... -- <action>...

Options:
  --dir <dir>       Directory to listen to
  --event <event>   Event to watch for
  <action>            Action to perform on file change
"""

# import strutils
import docopt

include state
# import state from .

proc parse_args(): State =
  let args = docopt(doc, version = "File watcher 1.0")
  return State(
    dirs: @(args["--dir"]),
    events: @(args["--event"]),
    action: @(args["<action>"])
  )
# if args["move"]:
#   echo "Moving ship $# to ($#, $#) at $# kn".format(
#     args["<name>"], args["<x>"], args["<y>"], args["--speed"])
#   ships[$args["<name>"]].move(
#     parseFloat($args["<x>"]), parseFloat($args["<y>"]),
#     speed = parseFloat($args["--speed"]))

# if args["new"]: 
#   for name in @(args["<name>"]): 
#     echo "Creating ship $#" % name 