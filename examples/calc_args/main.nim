import ski
from os import commandLineParams

let args = commandLineParams()
if args.len < 1:
  stderr.writeLine """
Need 1 argument.

Usage example:
  $ nim c -r examples/calc_args.nim Sxyz"""
  quit 1

let code = args[0]
echo "Before : " & code
echo "After  : " & code.calculate(combinators)