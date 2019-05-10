import ski

proc calculate(s: cstring): cstring {.exportc.} =
  result = ski.calculate($s, combinators, 1)