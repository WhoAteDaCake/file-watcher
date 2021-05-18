require "inotify"

module Constants
  LOOKUP = {
    "modify" => LibInotify::IN_MODIFY,
    "moved_to" => LibInotify::IN_MOVED_TO,
    "moved_from" => LibInotify::IN_MOVED_FROM,
    "move" => LibInotify::IN_MOVE,
    "create" => LibInotify::IN_CREATE,
    "delete" => LibInotify::IN_DELETE
  } 
  ALLOWED_EVENTS = LOOKUP.keys()
end