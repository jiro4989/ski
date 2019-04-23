# Package

version       = "1.1.0"
author        = "jiro4989"
description   = "ski is library for SKI combinator."
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 0.19.4"

task docs, "Generate documents":
  exec "nimble doc src/ski.nim -o:docs/ski.html"

task examples, "Execute example programs":
  withDir "examples/calc_args":
    exec "nim c -r main.nim Sxyz"
  exec "echo ---------------------"
  withDir "examples/read_file":
    exec "nim c -r main.nim"

task runCI, "Run CI tasks":
  exec "nimble test"
  exec "nimble docs"
  exec "nimble examples"