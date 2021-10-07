# Package

version       = "0.1.0"
author        = "Avahe Kellenberger"
description   = "A new awesome nimble package"
license       = "GPL-2.0-only"
srcDir        = "src"
bin           = @["cbot"]


# Dependencies

requires "nim >= 1.4.6"
requires "irc >= 0.4.0"

task release, "Build for release":
  exec "nim c -o:bin/cbot -d:release --opt:speed src/cbot.nim"
