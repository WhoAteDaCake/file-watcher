version     = "0.0.0"
author      = "Your name"
description = "Description of your library"
license     = "MIT"

srcDir = "src"

bin = @["fwatcher"]
binDir = "bin"

requires "nim >= 1.2.2"
requires "docopt"
requires "pipe"
requires "zero_functional"
requires "unpack"