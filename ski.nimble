# Package

version       = "0.1.0"
author        = "jiro4989"
description   = "SKI combinator library"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 0.19.4"

task docs, "Generate documents":
  exec "nimble doc src/ski.nim -o:docs/ski.html"
